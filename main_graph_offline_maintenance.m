%%% MPC-BASED SCHEDULING WITH MACHINE MAINTENANCE
clear; clc; close all;

%% Parameters of the problem
%%% Case study
P = [9 5 7 10 4 12
     4 7 3 7 1 10
     5 7 6 3000 10 1
     4 3 10 6 4 5
     2 4 7 3 5 2
     1 6 5 3 6 8];

P_0 = P; % Nominal processing time

P_max = P + 10; % Maximum processing time before maintenance

G_init0 = [1 2 3 4 5
           1 3 5 6 0
           1 2 3 4 6
           1 2 4 5 0
           1 2 5 6 0
           1 2 3 5 0
           1 3 4 6 0
           1 2 6 5 3
           1 4 6 5 3
           1 2 4 5 6
           1 3 4 5 0
           1 2 3 4 6
           1 3 4 6 0];
G_j0 = [1 1 2 2 3 3 4 4 5 5 6 6 6]';

% Set planned release time and real release time
Release_planned = [0 2 4 7 10 12]';
max_delay = 3; % max advance/delay on a job w.r.t. planned release time
horizon = 5; % prediction horizon for MPC-scheduling
Release_real = Release_planned + randi([-max_delay max_delay], [length(Release_planned) 1]);
Release_real(Release_real < 0) = 0; % Set release time to 0 as minimum release time
Release_real = sort(Release_real); % Avoid possible job swap
% Release_real used for test:
Release_real = [0 1 5 7 11 14]';

%%% TODO: Sort data by release time considering possible job swap
% R=[];
% for i=1:length(G_j0)
%     R=[R; Release_real(G_j0(i))];
% end
% sorted = table(G_init0,G_j0,R);
% sorted = sortrows(sorted,3);
% G_init0 = table2array(sorted(:,1));
% G_j0 = table2array(sorted(:,2));
% Release_real = sort(Release_real);
% P = P(unique(G_j0, 'stable'),:);
%%%

% Pre processing of data
M0 = max(max(G_init0));
[G, P, M_init, aux, aux_alt] = pre_processing_graph(G_init0, P);
J = length(unique(G_j0)); %jobs
M = max(max(G)); %machines
A = size(G_j0,1);%alternatives
D = compute_D_from_graph(G_init0,G_j0); % disjunctive connections (2 constraints for each connection)
BigM = 1e5;
LittleBigM= BigM*0.01;
% Get machine flexibility (which operations can be performed by each machine)
Flexibility = zeros(J,M);
for j=1:J
    get_alternative = find(G_j0 == j); % get alternatives for each job
    get_machines = unique(G(get_alternative,:)); % get all possible machines for the job j
    get_machines(get_machines == 0) = []; % Remove 0 element
    Flexibility(j, get_machines) = 1; % Set to 1 the ability of machines to handle job j
end

%% Solve problem
% Data for storing results and specific parameters of the scheduling algorithm
%sol_tot = struct('C', {}, 'c', [], 'delta', [], 'gamma', [], 's', []); %structure to save all the solutions
arrivals = unique(Release_real); % Find the events (i.e. release of products)
t = 0; % time
decay_coefficient = 5; % decaying in performances after completion of one task
time_to_repair = 20*ones(1,M); % repairing time of machines
time_disruption = LittleBigM*ones(1,M);
R = zeros(J,M); % Repairing matrix to save when a machine will end maintenance
reschedule_for_maintenance = 0; % flag for machine start maintenance
reschedule_for_repairing = 0; % flag for machine end maintenance
update_processing = 0; % flag for updating processing
maintenance_info = zeros(1,3); % machine, start_maintenance, end_maintenance
%% Each iteration is one unit of time
% Solve the problem before the start of the simulation, to get the
% offline solution
sol_offline = Graph_minimization(G_init0,G_j0,P, Release_real, [] ,M0, R, 0); %%TODO: cambiare in "release_planned" quando funziona tutto
while 1
   
    % Check if processing times need to be updated due to the completion of a task
    if ~isempty(sol_offline) && sum(sum(ismember(int8(sol_offline.c), t))) > 0
        [row, col] = find(int8(sol_offline.c) == t); % Find jobs which completed a task
        for el=1:size(row) % Loop through all jobs which completed a task
            if int8(sol_offline.c(row(el),col(el))) ~= int8(sol_offline.s(row(el),col(el))) % Consider only the completion of jobs in the chosen path (other jobs have start = completion)
                update_processing = 1;
                % Update processing time of the machine, for jobs  in the shop
                % that may pass through the machine after the current job
                for j_later=1:size(sol_offline.c,1) % Loop through all jobs
                    % If the job is scheduled to pass through that machine,
                    % or if the job is notscheduled but it may pass through
                    % that machine after dynamic re-routing due to other events
                    if (int8(sol_offline.s(j_later, col(el))) >= t) %|| ... % The job is scheduled to pass through that machine
                           % (Flexibility(j_later,col(el)) == 1 && int8(sol_offline.s(j_later, col(el))) == int8(sol_offline.c(j_later, col(el)))) % The job is not scheduled to pass through that machine
                        P(j_later,col(el)) = P(j_later,col(el)) + decay_coefficient;
                        % Check if machine needs maintenance because P > Pmax
                        if P(j_later,col(el)) >= P_max(j_later,col(el))
                            P(j_later,col(el)) = LittleBigM; % Machine unavailable
                            % Save the initial maintenance time and info
                            if time_disruption(col(el)) == LittleBigM
                                time_disruption(col(el)) = t;
                                maintenance_info(end+1,:) = [col(el) time_disruption(col(el)) time_disruption(col(el))+time_to_repair(col(el))];
                            end 
                                reschedule_for_maintenance = 1;
                        end
                    end
                end
%                 % Update processing time of the machine for jobs not arrived yet in the shop
%                 for j_later2=J:-1:j_later+1
%                     P(j_later2,col(el)) = P(j_later2,col(el)) + decay_coefficient;
%                     % Check if machine needs maintenance because P > Pmax
%                     if P(j_later2,col(el)) >= P_max(j_later2,col(el))
%                         P(j_later2,col(el)) = LittleBigM; % Machine unavailable
%                         if time_disruption(col(el)) == LittleBigM
%                             time_disruption(col(el)) = t; % Save the initial maintenance time
%                         end 
%                             reschedule_for_maintenance = 1;
%                     end
%                 end
            end
        end
    end
    % Check if a machine has just ended its maintenance
    for m=1:M
        if (t == (time_disruption(m)+time_to_repair(m)))
            for j_later=1:size(sol_offline.c,1) % Loop through all jobs
                % If the job is scheduled to pass through that machine,
                    % or if the job is not scheduled but it may pass through
                    % that machine after dynamic re-routing due to other events
                    % (Not sure if it is needed here)
                    if (int8(sol_offline.s(j_later, m)) >= t) %|| ... % 
                          %  (Flexibility(j_later,m) == 1 && int8(sol_offline.s(j_later, m)) == int8(sol_offline.c(j_later, m)))
                        % Restore processing time to nominal value
                        P(j_later,m) = P_0(j_later,m);
                        R(j_later,m) = time_disruption(m) + time_to_repair(m); % Save maintenance info for rescheduling
                    end
            end
            time_disruption(m) = LittleBigM; % Restore disruption time
            reschedule_for_repairing = 1;
        end
    end
    % If something happened
    % ---> keep the same routing and scheduling, but update processing and
    % consequently start/completion times
    if update_processing ||  reschedule_for_maintenance || reschedule_for_repairing
            sol_offline = Graph_minimizationUpdate_off(G_init0,G_j0,P, Release_planned, sol_offline,M0, R, t, time_disruption);
            update_processing = 0;
            reschedule_for_repairing = 0;
            reschedule_for_maintenance = 0;
    end
    
    % If the production process is completed, exit the while loop
    if size(sol_offline.c,1) == size(arrivals,1) && t > sol_offline.C 
        break
    end
    t = t + 1 ; % Update time
end

%% Plot offline solution
figure()
graph_Gantt(sol_offline, G_init0, G_j0, P, sol_offline.gamma, M0, "Schedule");
xlabel("Time", "FontSize", 15)
hold on
% % Plot maintenance time
line_handles = [];  % Initialize an empty array
if(maintenance_info(1,1) == 0)
    maintenance_info(1,:) = []; % Remove first row that is 0
end
for i=1:size(maintenance_info,1)
            current_line = plot(linspace(maintenance_info(i,2), maintenance_info(i,3), ...
                20), maintenance_info(i,1), '-x', "Color","red");
            line_handles = [line_handles, current_line];
            % Exclude this line from the legend
            set(current_line, 'HandleVisibility', 'off');
end