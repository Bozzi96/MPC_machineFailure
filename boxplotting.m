figure()
hold on
simulazioni = [time_simulaz_offline; time_simulaz_mpc]'
boxplot(simulazioni)
mean(time_simulaz_offline)
mean(time_simulaz_mpc)