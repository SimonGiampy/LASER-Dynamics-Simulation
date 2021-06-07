clear; % clear the workspace
close all; % closes the windows

%Constants
TIME_STEPS = 750;
LATTICE_WIDTH = 200;
LATTICE_HEIGHT = 200;
PHOTON_SATURATION = 25;

%Initialize System
cell.electron = 0;
cell.electronLife = 0;
cell.photonCount = 0;
cell.lifeTimes = zeros(1, PHOTON_SATURATION);

currAutomaton = repmat(cell, LATTICE_WIDTH, LATTICE_HEIGHT);
prevAutomaton = currAutomaton;

% Constant behavior input data
electronLifeTime = 100;
photonLifeTime = 16;
pumpingProbability = 0.0125;
stimulatedEmissionThreshold = 2;
thermalExcitingProbability = 0.005;
spontaneousEmissionProbability = 0.02;


%output data
populationCounter = zeros(1, TIME_STEPS);
photonCounter = zeros(1, TIME_STEPS);
spontaneousEmissionPhotons = zeros(1, TIME_STEPS);
thermalExcitingElectrons = zeros(1, TIME_STEPS);

%Time iteration
for t = 1:TIME_STEPS
    %Noise probability matrix
    noise = rand(LATTICE_WIDTH, LATTICE_HEIGHT);
    
    populationSum = 0;
    photonSum = 0;
    
    %For each cell
    for i = 1:LATTICE_WIDTH
        for j = 1:LATTICE_HEIGHT
            
            %Apply stimulated emission rule
            if currAutomaton(i, j).electron == 1 && currAutomaton(i, j).photonCount < PHOTON_SATURATION && ...
                    mooreNeighborhood(prevAutomaton, i, j, LATTICE_WIDTH, LATTICE_HEIGHT) >= stimulatedEmissionThreshold
                for index = 1:PHOTON_SATURATION
                    if currAutomaton(i, j).lifeTimes(index) == 0
                        currAutomaton(i, j).lifeTimes(index) = photonLifeTime;
                        currAutomaton(i, j).photonCount = currAutomaton(i, j).photonCount + 1; 
                        break;
                    end
                end
                currAutomaton(i, j).electron = 0;
                currAutomaton(i, j).electronLife = 0;
            end
            
            %Apply photon decay
            for index = 1:PHOTON_SATURATION
            	if currAutomaton(i, j).lifeTimes(index) > 0
                	currAutomaton(i, j).lifeTimes(index) = currAutomaton(i, j).lifeTimes(index) - 1; 
                    if currAutomaton(i, j).lifeTimes(index) == 0
                        currAutomaton(i, j).photonCount = currAutomaton(i, j).photonCount - 1; 
                    end
            	end
            end
            
            %Apply electron decay
            if currAutomaton(i, j).electron == 1 && currAutomaton(i, j).electronLife > 0
                currAutomaton(i, j).electronLife = currAutomaton(i, j).electronLife - 1; 
                if currAutomaton(i, j).electronLife == 0
                	currAutomaton(i, j).electron = 0;
                end
            end
            
            %Apply pumping rule
            if currAutomaton(i, j).electron == 0 && rand < pumpingProbability
                currAutomaton(i, j).electron = 1;
                currAutomaton(i, j).electronLife = electronLifeTime;
            end
            
            %Divided Thermal Exciting and spontaneous emission probability
            if currAutomaton(i, j).electron == 0 && noise(i, j) < thermalExcitingProbability
            	currAutomaton(i, j).electron = 1;
            	currAutomaton(i, j).electronLife = electronLifeTime;
                thermalExcitingElectrons(t) = thermalExcitingElectrons(t) + 1;
            elseif currAutomaton(i, j).electron == 1 && noise(i, j) < spontaneousEmissionProbability
                for index = 1:PHOTON_SATURATION
                    if currAutomaton(i, j).lifeTimes(index) == 0
                        currAutomaton(i, j).electron = 0;
                        currAutomaton(i, j).electronLife = 0;
                        currAutomaton(i, j).lifeTimes(index) = photonLifeTime;
                        currAutomaton(i, j).photonCount = currAutomaton(i, j).photonCount + 1;
                        spontaneousEmissionPhotons(t) = spontaneousEmissionPhotons(t) + 1;
                        break;
                    end
                end
            end
            
            %Partial sum of upper state electrons
            populationSum = populationSum + currAutomaton(i, j).electron;
            %Partial sum of total photons in the lattice
            photonSum = photonSum + currAutomaton(i, j).photonCount;
        end
    end
    
    %Calculate populations after this time step
    populationCounter(t) = populationSum;
    photonCounter(t) = photonSum;
    
    
    fprintf("Time step %d, %3.2f%% complete...\n", t, (t / TIME_STEPS * 100));
    
    %Update state
    prevAutomaton = currAutomaton;
end

%Final calculations
%Output results
figure(1);
grid on;
hold on;
title("Population inversion over time");
time = linspace(1, TIME_STEPS, TIME_STEPS);
plot(time, populationCounter);
plot(time, photonCounter);
plot(time, spontaneousEmissionPhotons);
plot(time, thermalExcitingElectrons)
legend('Population Inversion', 'Photon Count', 'Spontaneous Emission', 'Thermal Agitation');
xlabel('Time Step');
ylabel('Population');
hold off;


%Returns the number of photons in the adjacent cells using moore's
%neighborhood rule
function count = mooreNeighborhood(automaton, center_x, center_y, lattice_width, lattice_height)
    count = 0;
    
    min_x = max(center_x - 1, 1);
    max_x = min(center_x + 1, lattice_width);
    min_y = max(center_y - 1, 1);
    max_y = min(center_y + 1, lattice_height);
    
    for i = min_x:max_x
        for j = min_y:max_y
            count = count + automaton(i, j).photonCount;
        end
    end
end