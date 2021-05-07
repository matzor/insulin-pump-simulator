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
back_pressure = "off";       %"on"/"off", adds off-set to pressure.              

sim_gravity = "off";        %"on"/"off", simulates pressure effects caaused by gravity

random_friction = false;

% Pump settings
basal_rate = 1;             %[U/h]
n_pulses_per_hour = 20;      %number of motoractivations per hour for basal rate
                            
% Optional pump settings
%Give extra insulin bolus of n units at time x
bolus_size = 10;             %[U]
bolus_time = 3600*3;

%Simulate a pump stop
pump_stop_time = 3600*6;  %time at which basal pumping stops
                            %stop_time > sim_time means pumping will never
                            %stop during simulation


%% Insulin infusion set parameters
iis_diameter = 1;               %[mm]
iis_len = 0.6;                  %[m], 30-110cm
iis_element_len = iis_len/3;    %[m]
cannula_size = 0.286/2;         %[mm], radius
                                %cannula size range from 0.286 - 0.455mm
                                %diameter
iis_area = pi*iis_diameter^2;   %[mm^2]                           
iis_elevation = 0.5;            %[m], pump elevation relative to infusion site
                                %only active if sim_gravity == "on"

%static pressure-diameter coefficient, depends on IIS tube material
iis_pres_dia_value = 2e-10;  %[m/Pa] %5e-8

            
                                   
%% Pump parameters

%Infusion rate, 
%The speed of a bolus, the time it takes to infuse 1U
%Depends on pump model. Fast pumps take 2s, slower ones 40s
%Affects both basal rate and boluses
%s_per_U = 3.6;                 %[s], 10ml/h     
%s_per_U = 1.8;                 %[s], 20ml/h 
%s_per_U = 40;                  %[s], 0.9ml/h
%s_per_U = 2;   
%Alternatively, input in [ml/min]
flow_ml_min = 0.05;                                          %[ml/min]
s_per_U = 60/flow_ml_min / 100;                              %[s]

%Pump reservoir
reservoir_volume = 3;                                        %[ml]
reservoir_len = 2.5;                                         %[cm]
piston_length = reservoir_len;                               %[cm]
reservoir_radius = sqrt(reservoir_volume/(pi*piston_length));%[cm]
piston_area = pi*reservoir_radius^2;                         %[cm2]


%Pump mechanics
screw_lead = 0.1;                                            %[cm] per rotation
spring_k1 = 1.5e4;                                           %[N/m]
damper_d1 = 5.0e4;                                           %[N/(m/s)]


%Cylinder friction
f_c = 0.7;                                                   %[N]
f_cp = 1e-6;                                                 %[N/Pa]
f_brk_c = 1.1;                                               %[]
f_v = 10000;                                                 %[N/(m/s)]
v_limit = 0.5e-6;                                            %[cm/s]


%DC motor parameters
%using Faulhaber Series 0816 003 SR
m_volt_nom = 3;                                              %[V]
m_arm_res = 5.4;                                             %[ohm]
m_arm_inductance = 53;                                       %[uH]
m_back_emf = 0.000221;                                       %[V/rpm]
m_rotor_inertia = 0.051;                                     %[g*cm^2]


%% Fluid parameters
f_density = 1090; %998.21;                                   %[kg/m^3]
f_temp = 20;                                                 %[c*], from 20-40c
f_ph = 2;                       %1: pH 4.1, 2: pH 7.5, 3: pH 9.1
f_bmodulus = 2.1;                                            %[GPa]


%Patient simulator, [m]
pat_pressure_diameter = 5e-6;                                %[m]
pat_area = 2.5e-3;                                           %[m]
pat_len = 3.5e-3;                                            %[m]
pat_tau = 1500 / (60 / s_per_U);                             %[s]
pat_dissipation = 2e-4;                                      %[mm^s]

%% Randomizing parameters (IF set to true)

if random_friction == true
    %Pump mechanics
    spring_k1 = 1e4 + (1e5 - 1e4)*rand                                           %[N/m]
    damper_d1 = 1e4 + (1e5 - 1e4)*rand                                           %[N/(m/s)]
    %Cylinder friction
    f_c = 0.5 + (1.5- 0.5)*rand                                                   %[N]
    f_brk_c = 1 + (1.5 - 1)*rand                                               %[]
    %Fluid parameters
    f_temp = randi([20, 40])                                                 %[c*], from 20-40c
    f_ph = randi([1, 3])                       %1: pH 4.1, 2: pH 7.5, 3: pH 9.1
    %Patient simulator, [m]
    pat_pressure_diameter = 1e-6 + (10e-6 - 1e-6)*rand                                %[m]
    pat_area = 1e-3 + (3e-3 - 1e-3)*rand                                           %[m]
    pat_len = 1e-3 + (4e-3 - 1e-3)*rand                                            %[m]
    pat_dissipation = 1e-4 + (4e-4 - 1e-4)*rand                                     %[mm^s]
end

%% Calculating various system values
%NB: modifying anything below may break simulator

U_per_ml = 1/100;                                            %1U = 1/100ml
m_volt = m_volt_nom;                                         %[V], change motor voltage to change infusion speed (s_per_u)

%calculating step sizes
u_per_basal_pulse = basal_rate / n_pulses_per_hour;
m_pulse_width = u_per_basal_pulse * s_per_U;
m_pulse_period = 3600 / n_pulses_per_hour;
piston_displacement_per_unit = U_per_ml / (piston_area);  %[cm]
piston_displacement_per_basal_dose = piston_displacement_per_unit * u_per_basal_pulse;    %[cm]

%setting gear box ratio
input_rpm = 13570;
%input_rpm = 2262;
output_rpm = 60/s_per_U * piston_displacement_per_unit/screw_lead;
gear_ratio = input_rpm / output_rpm;

% Calculating fluid viscosity
f_temperature = [20 25 30 35 40];                            %[c*]
f_ph_values = [4.1 7.5 9.1];                                 %[pH]
temp_range = 20:40;
% Insulin viscosity depend on temperature (col) and pH (row)
% data from Bohidar1998
                                %20 25  30  35  40  degrees C
insulin_intrinsic_viscosity =   [12 22  45  87  145    %pH 4.1
                                 9  19  31  62  119    %pH 7.5
                                 10 17  30  55  77];   %pH 9.1
%Fitting viscosities to a curve
f_pol4 = polyfit(f_temperature, insulin_intrinsic_viscosity(1,:), 2);
f_pol7 = polyfit(f_temperature, insulin_intrinsic_viscosity(2,:), 2);
f_pol9 = polyfit(f_temperature, insulin_intrinsic_viscosity(3,:), 2);
intrinsic_viscosity = [ polyval(f_pol4, temp_range)
                        polyval(f_pol7, temp_range)
                        polyval(f_pol9, temp_range)];

f_intrinsic_viscosity = intrinsic_viscosity(f_ph, f_temp-19)  %[cc/g]
f_intrinsic_viscosity = f_intrinsic_viscosity * 10e-6 / 10e-3;%[m^3/kg]
f_viscosity = f_intrinsic_viscosity / f_density;             %[m^2/s]



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
    patient_pressure = -130;            %[Pa], = -1.3mBar
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
