function [] = plot_simulation(simdata, save_figures, filename)
%PLOT_SIMULATION Plots results from pump simulation
%   plots tube pressure, flow, pulse volume, cumulative volume, piston
%   position, piston force, motor voltage, motor current

    %converting time format
    s = seconds(simdata.p_tube.p1.Time);
    s.Format = 'hh:mm:ss';
    simdata.p_tube.p1.TimeInfo.Units = 'hours';
    
    
    tstart = seconds(0);
    tend = seconds(inf);
    %tstart = seconds(3600*12);
    %tend = seconds(3600*2 + 60*30);
    tstart.Format = 'hh:mm:ss';
    tend.Format = 'hh:mm:ss';
    
    xaxis_lim = [tstart tend];
    yaxis_lim = [0 inf];

    %Tube pressure
    figure();
    plot(s, simdata.p_tube.p1.Data);
    xlim(xaxis_lim);
    grid on;
    title("Infusion tube pressure");
    ylabel("Pressure (Pa)");
    xlabel("Time (hh:mm:ss)");
    movegui("northwest");
    if save_figures == true
        filename_suffix = filename+".png";
        saveas(gcf, "plot/p_tube"+filename_suffix);
    end
    
%     %Tube pressure
%     figure();
%     plot(s, simdata.p_tube.p1.Data);
%     hold on;
%     plot(s, simdata.p_tube.p4.Data);
%     grid on;
%     title("Infusion tube pressure");
%     legend("Pump-side pressure","Patient-side pressure");
%     ylabel("Pressure (Pa)");
%     movegui("northwest");
    
%     %Tube pressure
%     figure();
%     p1 = simdata.p_tube.getsamples(2300:2460);
%     plot(p1);
%     grid on;
%     title("Tube pressure");
%     ylabel("(Pa)");
%     movegui("northwest");

    %Insulin flow [U/s] out of needle
    figure();
    plot(s, simdata.flow_tube.Data);
    xlim(xaxis_lim);
    grid on;
    title("Flow of insulin");
    movegui("north");
    ylabel("Flow (U/s)");
    xlabel("Time (hh:mm:ss)");
    if save_figures == true
        saveas(gcf, "plot/flow_tube"+filename_suffix);
    end
    
    %Insulin flow [U/s] out of pump
    m3_to_u = 1000 * 1000 * 100;
    figure();
    f1 =  simdata.flow.f1.Data * m3_to_u;
    plot(s,f1);
    xlim(xaxis_lim);
    grid on;
    title("Flow of insulin out of pump");
    movegui("north");
    ylabel("Flow (U/s)");
    xlabel("Time (hh:mm:ss)");
    if save_figures == true
        saveas(gcf, "plot/flow_pump"+filename_suffix);
    end

    %Insulin pulse volume
    figure();
    [peaks, locs] = findpeaks(simdata.pulse_volume.signals.values, simdata.pulse_volume.time);
    s_locs = seconds(locs);
    s_locs.Format = 'hh:mm:ss';
    scatter(s_locs, peaks);
    ylim([0 0.06]);
    xlim(xaxis_lim);
    grid on;
    title("Pulse volume");
    movegui("southwest");
    ylabel("Units per pulse (U)");
    xlabel("Time (hh:mm:ss)");
    if save_figures == true
        saveas(gcf, "plot/pulse_volume"+filename_suffix);
    end

    %Cumulative volume
    figure();
    plot(s, simdata.volume_tube.Data);
    xlim(xaxis_lim);
    grid on;
    title("Cumulative volume");
    movegui("northeast");
    ylabel("Volume (U)");
    xlabel("Time (hh:mm:ss)");
    if save_figures == true
        saveas(gcf, "plot/volume_tube"+filename_suffix);
    end

    %Piston position
    figure();
    simdata.pos_piston = simdata.pos_piston;
    plot(s, simdata.pos_piston.Data);
    xlim(xaxis_lim);
    hold on;
    plot(s, simdata.pos_piston_est.Data);
    grid on;
    title("Piston position");
    legend("Actual position","Target position");
    ylabel("Position (cm)");
    xlabel("Time (hh:mm:ss)");
    movegui("center");
    if save_figures == true
        saveas(gcf, "plot/pos_piston"+filename_suffix);
    end

    %Plunger force
    figure();
    plot(s, simdata.force_piston.Data);
    xlim(xaxis_lim);
    grid on;
    title("Force measurement");
    ylabel("Plunger force (N)");
    xlabel("Time (hh:mm:ss)");
    movegui("west");
    if save_figures == true
        saveas(gcf, "plot/force_piston"+filename_suffix);
    end

    %Motor voltage
    figure();
    plot(s, simdata.m_voltage.Data);
    xlim(xaxis_lim);
    title("Motor voltage");
    xlabel("Time (hh:mm:ss)");
    ylabel("Volt (V)");
    movegui("east");
    if save_figures == true
        saveas(gcf, "plot/m_voltage"+filename_suffix);
    end

    %Motor current
    figure();
    plot(s, simdata.m_current.Data);
    xlim(xaxis_lim);
    title("Motor current");
    ylabel("Current (A)");
    xlabel("Time (hh:mm:ss)");
    movegui("east");
    if save_figures == true
        saveas(gcf, "plot/m_current"+filename_suffix);
    end


    %% Detecting occlusion based on motor current draw
    %occ_off = load("plot/simdata_occlusion_off.mat");
    %occ_on = load("plot/simdata_occlusion_on.mat");
    %I_diff = occ_on.simdata.m_current - occ_off.simdata.m_current
    %figure();
    %plot(I_diff)
    %title("Difference in motor current after occlusion")
    %ylabel("(A)")
    %xlabel("Time (Seconds)")
    %saveas(gcf, "plot/m_current_difference_occ_on_off.png");

end

