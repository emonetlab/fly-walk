function interactions = wasThisFlyInteracting(f,this_fly,frame_num)

% collects all collisions and overlaps of a given list
if nargin == 2
    frame_num = f.current_frame-1;
end

interactions = [];

interactions = [interactions,getColl(f,this_fly,frame_num)];
interactions = [interactions,getOver(f,this_fly,frame_num)];

interactions = unique(interactions);
int_temp = interactions;
% get interactions of interactions
if ~isempty(int_temp)
    for i = 1:length(int_temp)
        interactions = [interactions,getColl(f,int_temp(i),frame_num)];
        interactions = [interactions,getOver(f,int_temp(i),frame_num)];
    end
    interactions = unique(interactions);
end

% remove itself
interactions(interactions==this_fly) = [];
        
