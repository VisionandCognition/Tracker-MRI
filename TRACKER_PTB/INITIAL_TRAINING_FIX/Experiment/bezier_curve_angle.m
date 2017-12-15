function pts = bezier_curve_angle(pt1, pt4, angle1, angle4, d1, d4, npoints)

t = linspace(0,1,npoints);

pt2 = pt1 + d1 * [cos(angle1*pi/180); -sin(angle1*pi/180)];
pt3 = pt4 + d4 * [cos(angle4*pi/180); -sin(angle4*pi/180)];
pts = kron((1-t).^3,pt1) + kron(3*(1-t).^2.*t,pt2) + kron(3*(1-t).*t.^2,pt3) + kron(t.^3,pt4);
return