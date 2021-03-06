function [ cycle, period, amplitude, mean_cycle ] = extract_cycle( y, tspan, tol, min_period )
%EXTRACT_CYCLE extracts cyclic pattern and cycle properties
% input: y - vector (in time ) ofsystem state dynamics - cyclic only (no transients)
%        tspan - vector of corresponding time instances
%        tol - numerical tolerance to determine repeated values
%        min_period - minimum period length in indices

cycle_y_max = max(y);
found_start = 0; %flag whether or not max has been reached yet

%loop through state vector y
for t = 2:size(tspan,2)-1
    if abs(cycle_y_max-y(t)) <= tol 
        if found_start == 0
            cycle_start = t;
            found_start = 1;
        else if t - cycle_start > min_period
            cycle_end = t-1;
            break;
            end
        end
    end
end


cycle = y(cycle_start:cycle_end);
period = tspan(cycle_end) - tspan(cycle_start);
mean_cycle = mean(cycle);
amplitude = max(cycle-mean_cycle);

%check whether cycle persists throughout given state history
% cycle_til_end = repmat(cycle, 1, round((size(tspan,2)-cycle_start)/(cycle_end-cycle_start))+1);

for t = (size(tspan,2) - (cycle_end-cycle_start)):size(tspan,2)-100
    %check if y -> 0
   if abs(y(t))+abs(y(t+100)) < 10^(-2)
       display(num2str(tspan(t)));
       error('cycle does not persist');
   end
end


end

