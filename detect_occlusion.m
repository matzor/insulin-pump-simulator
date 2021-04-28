function [occ_detected,occ_time] = detect_occlusion(simdata)
%DETECT_OCCLUSION Attempt to detect occlusion based on system states
%   Function finds pressure peaks and time constant of pressure dissipation 
%   of said peaks. If 3 subsequent pressure peaks are strictly increasing
%   AND time constant of pressure drop is greater than threshold, occlusion
%   is detected. 
%   Inputs: 
%       simdata: simulation results from insulin insulin_pump.m
%   Returns:
%       occ_detected: true/false 
%       occ_time:   0 if no occlusion detected, time of first detection if
%                   occ_detected == true

    s = seconds(simdata.p_tube.p1.Time);
    s.Format = 'hh:mm:ss';

    %% Finding pressure peaks
    [peaks, locs] = findpeaks(simdata.p_reservoir.signals.values, simdata.p_reservoir.time);

    % sometimes findpeaks marks local maximas between pulses as peaks
    % these are removed here
    p_0 = simdata.p_tube.p1.Data(1);
    k = find(peaks < p_0 + 10);
    peaks(k) = [];
    locs(k) = [];
%     for i = size(peaks):-1:1
%         if peaks(i) < p_0 + 10
%             peaks(i) = [];
%             locs(i) = [];
%         end
%     end

    s_locs = seconds(locs);
    s_locs.Format = 'hh:mm:ss';

%     plot_p_peaks = figure();
%     scatter(s_locs, peaks);
%     movegui("south");
%     title("Pressure peaks");
%     ylabel("Pressure (Pa)");
%     xlabel("Time (hh:mm:ss)");

%     plot_p = figure(); %for visualizing time constant
%     movegui("south");
%     plot(s, simdata.p_tube.p1.Data);
%     hold on;
%     grid on;

    %% Finding the time-constant of the exponential decau of the pressure peaks

    P = simdata.p_tube.p1.Data;
    time_constants = zeros(size(peaks));
    for peak = 1:size(peaks)-1
        p_peak = peaks(peak);
        min_idx = find(s == s_locs(peak));
        max_idx = find(s == s_locs(peak+1));
        p = simdata.p_tube.p1.Data(min_idx:max_idx);
        
        %find pressure before pulse, subtracted later
        idx_before_peak = find(s < (s(min_idx) - seconds(2)), 1, 'last');
        p_0 = P(idx_before_peak(end));
        
        
        p_peak = peaks(peak);
        idx = find(p_peak - p >= 0.63*p_peak , 1, 'first');
        
        if idx > 1
            tc_idx = min_idx + idx;
            tau = s(tc_idx) - s(min_idx);
            %xline(s(tc_idx), '--'); %for visualizing time constant
        else
            tau = seconds(180);  
            tau.Format = 'hh:mm:ss';
        end

        time_constants(peak) = seconds(tau);
        
    end

%     plot_tau = figure();
%     scatter(s_locs, time_constants);
%     title("Time constant of pressure peaks exponential decay");
%     ylabel("Time constant (seconds)");
%     xlabel("Pulse");
%     movegui("south");

    %% Checking for signs of occlusion 
    tau_limit = 5;
    p_limit = 10000;
    occ_detected = false;
    occ_time = 0;
    occ_idx = 0;
    for peak = 2:size(peaks)-1
        if peaks(peak-1) < peaks(peak) && peaks(peak) < peaks(peak+1)
            if time_constants(peak) > tau_limit
                occ_detected = true;
                occ_idx = peak;
                occ_time = s_locs(occ_idx+1);
                break;
            end
        elseif peaks(peak) > p_limit
            occ_detected = true;
            occ_idx = peak;
            occ_time = s_locs(occ_idx);
            break;
        end
    end
    
%     if occ_detected == true
%         figure(plot_tau);
%         xline(s_locs(occ_idx), '--');
%         figure(plot_p_peaks);
%         xline(s_locs(occ_idx), '--');
%     end
    
    figure();
    movegui("south");
    yyaxis left;
    scatter(s_locs, time_constants);
    ylabel('Timeconstant (seconds)');
    xlabel("Time (hh:mm:ss)");
    yyaxis right;
    scatter(s_locs, peaks);
    ylabel('Pressure peak (Pa)');
    legend('Timeconstants','Pressure peaks');
    legend('Location','northwest')
    if occ_detected == true
        xline(s_locs(occ_idx), '--');
        legend('Time constants','Pressure peaks', 'Occlusion detected');
    end
    
end


