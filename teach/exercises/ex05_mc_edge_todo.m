%% ex05_mc_edge_todo
% Given two corner values and positions, interpolate the iso crossing.
% This is THE key formula inside Marching Cubes.

iso = 300;
v0 = 100;   % below
v1 = 500;   % above
p0 = [0 0 0];
p1 = [1 0 0];

% TODO: t = ?;  p = ?
t = NaN;
p = [NaN NaN NaN];

assert(isfinite(t), 'Fill t = (iso-v0)/(v1-v0)');
fprintf('t=%.3f  p=%s  (expect t=0.5, p=[0.5 0 0] for these numbers)\n', t, mat2str(p));
