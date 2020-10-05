  function f = checkNflipOrientation(f,this_fly)
  % compares the adjacent angles and corrects the flip if there is one
  
  if (f.current_frame==1)
      return
  end
    
  if angleBWorientations(f.tracking_info.orientation(this_fly,f.current_frame-1)/180*pi,...
          f.tracking_info.orientation(this_fly,f.current_frame)/180*pi)>120/180*pi % if flipped orientation received
      f.tracking_info.orientation(this_fly,f.current_frame) = mod(f.tracking_info.orientation(this_fly,f.current_frame)+180,360);
  elseif angleBWorientations(f.tracking_info.orientation(this_fly,f.current_frame-1)/180*pi,...
          f.tracking_info.orientation(this_fly,f.current_frame)/180*pi)>f.maxAllowedTurnAngle % if grooming or something
      f.tracking_info.orientation(this_fly,f.current_frame) = f.tracking_info.orientation(this_fly,f.current_frame-1);
  end
