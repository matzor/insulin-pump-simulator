%%% Insulin pump simulator
%%Based on https://se.mathworks.com/videos/modeling-an-insulin-infusion-pump-87684.html
close all;
clear all;


%% Simulation parameters
sim_time = 3600 * 10;

plot_results = true;
save_figures = false;


occlusion = "off";          %"on"/"off", occlusion starts at occ_time, 
                            %"partial", "gradual"
occ_time = 3600*2;          %time occlusion occurs if "on"
iis_needle = "on";          %"on"/"off", to test effect of narrowing delivery 
                            %path through needle
back_pressure = "off";       %"on"/"off", adds off-set to pressure. Remove this?               

sim_gravity = "off";        %"on"/"off", simulates pressure effects caaused by gravity

% Pump settings
basal_rate = 1;             %[U/h]
n_pulses_per_hour = 20;      %number of motoractivations per hour for basal rate
                            %should probably depend on basal rate
                            
% Optional pump settings
%Give extra insulin bolus of n units at time x
bolus_size = 10;             %[U]
bolus_time = 3600*3;

%Simulate a pump stop
pump_stop_time = 3600*6;  %time at which basal pumping stops
                            %stop_time > sim_time means pumping will never
                            %stop during simulation

%% System parameters

%The speed of a bolus, the time it takes to infuse 1U
%Depends on pump model. Fast pumps take 2s, slower ones 40s
%Affects both basal rate and boluses
%s_per_U = 3.6;                  %[s], 10ml/h     
%s_per_U = 1.8;                 %[s], 20ml/h 
%s_per_U = 40;                  %[s], 0.9ml/h
%s_per_U = 2;   

flow_ml_min = 0.05;
s_per_U = 60/flow_ml_min / 100;

%Insulin infusion set parameters
iis_diameter = 1;               %[mm]
iis_len = 0.6;                  %[m], 30-110cm
cannula_size = 0.286/2;         %[mm], radius
                                %cannula size range from 0.286 - 0.455mm
                                %diameter
iis_area = pi*iis_diameter^2;   %[mm^2]                           
iis_elevation = 0.5;            %[m], pump elevation relative to infusion site
                                %only active if sim_gravity == "on"

%static pressure-diameter coefficient, depends on IIS tube material
iis_pres_dia_value = 2e-10;  %[m/Pa] %5e-8

             

% Physical parameters of the electromechanical pump system

%length of each tube element
iis_element_len = iis_len/3;                                    %[m]
                                   
%%Pump parameters
%Pump reservoir
reservoir_volume = 3;                                           %[ml]
reservoir_len = 2.5;                                            %[cm]
piston_length = reservoir_len;                                  %[cm]
reservoir_radius = sqrt(reservoir_volume/(pi*piston_length));   %[cm]
piston_area = pi*reservoir_radius^2;                            %[cm2]

%Pump mechanics
screw_lead = 0.1;                                              %[cm] per rotation
%gear_ratio = 9.00e+04;              %9.00e+03 gives infusion speed of 0.9ml/h (with piston len=3cm),
                                    %or 1U in 40s, same as Medtronic Minimed Paradigm 512
                                    %Found empirically by testing   


% %Cylinder friction
% f_c = 0.7;                                                %[N]
% f_cp = 1e-6;                                              %[N/Pa]
% f_brk_c = 1.1;                                            %[]
% f_v = 10000;                                                %[N/(m/s)]
% v_limit = 0.5e-6;                                           %[cm/s]
% spring_k1 = 1.5e4;                                        %[N/m]
% spring_k2 = 50;                                        %[N/m]
% damper_d1 = 5.0e4;                                        %[N/(m/s)]
% damper_d2 = 5;                                        %[N/(m/s)]

f_c = 0.7;                                                %[N]
f_cp = 1e-6;                                              %[N/Pa]
f_brk_c = 1.1;                                            %[]
f_v = 10000;                                                %[N/(m/s)]
v_limit = 0.5e-6;                                           %[cm/s]
spring_k1 = 1.5e4;                                        %[N/m]
spring_k2 = 50;                                        %[N/m]
damper_d1 = 5.0e4;                                        %[N/(m/s)]
damper_d2 = 5;                                        %[N/(m/s)]

%DC motor parameters
%using Faulhaber Series 0816 003 SR
m_volt_nom = 3;                                                 %[V]
m_arm_res = 5.4;                                                %[ohm]
m_arm_inductance = 53;                                          %[uH]
m_back_emf = 0.000221;                                          %[V/rpm]
m_rotor_inertia = 0.051;                                        %[g*cm^2]

% %using Faulhaber Series 0816 006 SR
% m_volt_nom = 6;                         %[V]
% m_arm_res = 21.2;                       %[ohm]
% m_arm_inductance = 217;                 %[uH]
% m_back_emf = 0.000431;                  %[V/rpm]
% m_rotor_inertia = 0.052;                %[g*cm^2]
% gear_ratio = 9.2807e+03;

%Fluid parameters
%
f_density = 1090; %998.21;                                     %[kg/m^3]
f_intrinsic_viscosity = 9;                                      %[cc/g] @20c
%f_intrinsic_viscosity = 119;                                   %[cc/g] @40c
f_intrinsic_viscosity = f_intrinsic_viscosity * 10e-6 / 10e-3;  %[m^3/kg]
f_viscosity = f_intrinsic_viscosity / f_density;                %[m^2/s]
f_bmodulus = 2.1;                                               %[GPa]

%Patient simulator, [m]
% pat_pressure_diameter = 1.5e-5;
% pat_area = 2e-3;
% pat_len = 0.5e-3;
% pat_tau = 120;
% pat_dissipation = 1.5e-3;

%Patient simulator, [m]
pat_pressure_diameter = 5e-6;
pat_area = 2.5e-3;
pat_len = 3.5e-3;
pat_tau = 1500 / (60 / s_per_U);
pat_dissipation = 2e-4;

%% Calculating various system values
%NB: modifying anything below may break simulator

U_per_ml = 1/100;                           %1U = 1/100ml
%base_flow = 0.9;                            %[ml/h]
%new_flow = U_per_ml/s_per_U * 60 * 60;      %[ml/h]
%flow_modifier = new_flow/base_flow;
m_volt = m_volt_nom;% * flow_modifier;        %[V], change motor voltage to change infusion speed (s_per_u)

u_per_basal_pulse = basal_rate / n_pulses_per_hour;
m_pulse_width = u_per_basal_pulse * s_per_U;
m_pulse_period = 3600 / n_pulses_per_hour;
piston_displacement_per_unit = U_per_ml / (piston_area);%piston_length/(reservoir_volume * 100);  %[cm]
piston_displacement_per_basal_dose = piston_displacement_per_unit * u_per_basal_pulse;    %[cm]

%default_res_len = 3.0;                    %[cm]
%gear_modifier = default_res_len / reservoir_len;
%gear_ratio = gear_ratio * gear_modifier;

input_rpm = 13570;
%input_rpm = 2262;
output_rpm = 60/s_per_U * piston_displacement_per_unit/screw_lead;
gear_ratio = input_rpm / output_rpm;


%IIS with or without cannula
if iis_needle == "on"
    cannula_size = cannula_size;
else
    cannula_size = iis_diameter/2;
end
cannula_area = pi*(cannula_size)^2;

%occlusion on or off
occ_sw = 0;
occ_tau = 1;
if occlusion == "on"
    occ_area = 1e-16;
elseif occlusion == "partial"
    occ_area = iis_area/10000000000;
elseif occlusion == "gradual"
    occ_sw = 1;
    occ_area = iis_area;    
    occ_tau = 2000;
else
    occ_area = iis_area;
end

%Back pressure
if back_pressure == "on"
    %TODO: Doesn't make sense to use blood pressure (I think),
    %      need to find pressure inside SC tissue
%     bp_sys = 120;                                       %blood pressure [mmHg]
%     bp_dia = 80;
%     bp_map = (bp_sys + 2*bp_dia)/3 * 133.32239;         %average BP in pascal
    patient_pressure = 130; %-1.3mBar
else
    patient_pressure = 0;
end

%gravity affects due to pump elevation relative to infusion site
if sim_gravity == "on"
    iis_elevation = iis_elevation;
    iis_element_elevation = iis_element_len;
else
    iis_elevation = 0;
    iis_element_elevation = 0;
end


%% Simulate and plot

close all;
simdata = sim('pump_simulator',sim_time);

filename =  "_t"+sim_time           + ...
            "_basal"+basal_rate     + ... 
            "_bolus"+bolus_size     + ...
            "_occlusion_"+occlusion + ...
            "_gravity_"+sim_gravity;
if pump_stop_time < sim_time
    filename = filename + "_pumpstop"+pump_stop_time;
end

if plot_results == true
    plot_simulation(simdata, save_figures, filename);
end

if save_figures == true
    filename = "data/simdata"+filename+".mat";
    save(filename, "simdata");
end



[occ_detected, occ_det_time] = detect_occlusion(simdata)