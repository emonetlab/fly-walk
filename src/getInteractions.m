function interactions = getInteractions(f,these_flies,frame_num)
% collects all collisions and overlaps of a given list

if f.current_frame==1
    interactions = [];
    return
end

if nargin == 2
    frame_num = f.current_frame-1;
end

interactions = [];

for i = 1:length(these_flies)
    this_fly = these_flies(i);
    interactions = [interactions,getColl(f,this_fly,frame_num)];
    interactions = [interactions,getOver(f,this_fly,frame_num)];
end

interactionst = interactions;
% go over these now
for i = 1:length(interactionst)
    this_fly = interactionst(i);
    interactions = [interactions,getColl(f,this_fly,frame_num)];
    interactions = [interactions,getOver(f,this_fly,frame_num)];
end

interactions = unique(interactions);

% remove the input flies from the listin
for i = 1:length(these_flies)
    interactions(interactions==these_flies(i)) = [];
end

