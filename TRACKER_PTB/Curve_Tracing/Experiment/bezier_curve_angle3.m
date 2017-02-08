function pts = bezier_curve_angle3(pt1, pt3, angle1, d1, npoints)

t = linspace(0,1,npoints);

pt2 = pt1 + d1 * [cos(angle1*pi/180); -sin(angle1*pi/180)];
%pts = kron((1-t).^3,pt1) + kron(3*(1-t).^2.*t,pt2) + kron(3*(1-t).*t.^2,pt3) + kron(t.^3,pt4);
pts = kron((1-t).^2,pt1) + kron(2*(1-t).*t,pt2) + kron(t.^2,pt3);

return