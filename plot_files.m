close all;
clear all;

rgb =[0.8500    0.3250    0.0980
         0    0.4470    0.7410
    0.9290    0.6940    0.1250
    0.4940    0.1840    0.5560
    0.4660    0.6740    0.1880
    0.3010    0.7450    0.9330
    0.6350    0.0780    0.1840];

data1 = open("data/simdata_t72000_basal1_bolus0_occlusion_off_gravity_off.mat");
data2 = open("data/simdata_t72000_basal1_bolus0_occlusion_gradual_gravity_off.mat");

occlusion = "Gradual occlusion";

%converting time format
s1 = seconds(data1.simdata.p_tube.p1.Time);
s2 = seconds(data2.simdata.p_tube.p1.Time);
s1.Format = 'hh:mm:ss';
s2.Format = 'hh:mm:ss';

tstart = seconds(0);
tend = seconds(inf);
%tstart = seconds(3600*2 );
%tend = seconds(3600*2 + 60*10);
tstart.Format = 'hh:mm:ss';
tend.Format = 'hh:mm:ss';
xaxis_lim = [tstart tend];

m3_to_u = 1000 * 1000 * 100; %m3 to l, l to ml, ml to u


p1 = data1.simdata.p_tube.p1.Data;
p2 = data2.simdata.p_tube.p1.Data;
%p_occ = data2.simdata.p_tube();

f1 = data1.simdata.force_piston.Data;
f2 = data2.simdata.force_piston.Data;

%pos1 = data1.simdata.pos_piston;
%pos2 = data2.simdata.pos_piston;


%% Pressure
figure();
colororder(rgb);
hold on;
grid on;
plot(s2, p2);
plot(s1, p1);
xlim(xaxis_lim);
title("Infusion tube pressure");
legend(occlusion, "No occlusion");
ylabel("Pressure (Pa)");
xlabel("Time (hh:mm:ss)");

%% Force
figure();
colororder(rgb);
hold on;
grid on;
plot(s2, f2);
plot(s1, f1);
xlim(xaxis_lim);
title("Force measurement");
ylabel("Plunger force (N)");
xlabel("Time (hh:mm:ss)");
legend(occlusion,"No occlusion");


% figure();
% colororder(rgb);
% hold on;
% grid on;
% plot(s2(49974:50131), f2(49974:50131));
% plot(s1(49958:50125), f1(49958:50125));
% title("Piston force");
% legend("Partial occlusion","No occlusion");
% ylabel("(N)");
%% old plots,
% %% Pressure
% figure();
% hold on;
% grid on;
% plot(s1, p1);
% plot(s2, p2);
% title("Tube pressure");
% legend("No occlusion",occlusion);
% ylabel("(Pa)");
% 
% %% Pressure, occ only
% figure();
% hold on;
% grid on;
% plot(p_occ.p1);
% plot(p_occ.p2);
% plot(p_occ.p3);
% plot(p_occ.p4);
% title("Tube pressure");
% legend("p1","p2", "p3", "p4");
% ylabel("(Pa)");
% 
% %% Force
% figure();
% colororder(rgb);
% hold on;
% grid on;
% plot(f2);
% plot(f1);
% title("Piston force");
% legend("Occlusion","No occlusion");
% ylabel("(N)");
% 
% % %% Flow
% % figure();
% % hold on;
% % grid on;
% % plot(q1.f1);
% % plot(q2.f1);
% % title("Insulin flow");
% % legend("No occlusion","Occlusion");
% % ylabel("(U/s)");
% 
%% Flow

m3_to_u = 1000 * 1000 * 100; %m3 to l, l to ml, ml to u
q1 = data1.simdata.flow;
q2 = data2.simdata.flow;
q1.f1 = q1.f1 * m3_to_u;
q2.f1 = q2.f1 * m3_to_u;
q2.f2 = q2.f2 * m3_to_u;
q2.f3 = q2.f3 * m3_to_u;

figure();
hold on;
grid on;
plot(s1, q1.f1.Data);
plot(s2, q2.f1.Data);
%plot(s2, q2.f3.Data);
xlim(xaxis_lim);
title("Flow of insulin");
legend("No occlusion","Occlusion");
ylabel("Flow (U/s)");
xlabel("Time (hh:mm:ss)");

figure();
hold on;
grid on;
plot(s2, q2.f1.Data);
plot(s2, q2.f2.Data);
plot(s2, q2.f3.Data);
xlim(xaxis_lim);
title("Flow of insulin");
legend("Flow 1","Flow 2", "Flow 3");
ylabel("Flow (U/s)");
xlabel("Time (hh:mm:ss)");



%% Piston position
figure();
hold on;
grid on;
plot(s1, data1.simdata.pos_piston.Data);
plot(s2, data2.simdata.pos_piston.Data);
xlim(xaxis_lim);
legend("No occlusion","Occlusion");
title("Piston position");
ylabel("Position (cm)");
xlabel("Time (hh:mm:ss)");

%% Plots for PARTIAL OCCLUSION

% Pulse volume
[peaks, locs] = findpeaks(data2.simdata.pulse_volume.signals.values, data2.simdata.pulse_volume.time);
s_locs = seconds(locs);
s_locs.Format = 'hh:mm:ss';

figure();
scatter(s_locs, peaks);
grid on;
title("Pulse volume");
ylabel("Units per pulse (U)");
xlabel("Time (hh:mm:ss)");

% Flow pump vs needle
q_needle = data2.simdata.flow_tube.Data;
q_needle_no_occ = data1.simdata.flow_tube.Data;

figure();
hold on;
grid on;
plot(s2, q2.f1.Data);
plot(s2, q_needle);
xlim(xaxis_lim);
title("Flow of insulin");
legend("Flow out of pump","Flow out of needle");
ylabel("Flow (U/s)");
xlabel("Time (hh:mm:ss)");

figure();
hold on;
grid on;
plot(s1, q1.f1.data);
plot(s2, q2.f1.Data);
plot(s1, q_needle_no_occ, '--');
plot(s2, q_needle, '--');

xlim(xaxis_lim);
title("Flow of insulin");
legend("Flow out of pump (no occlusion)","Flow out of pump (partial occlusion)","Flow out of needle (no occlusion)","Flow out of needle (partial occlusion)");
ylabel("Flow (U/s)");
xlabel("Time (hh:mm:ss)");
