function jarList = getOmeroJars()
% GETOMEROJARS List the JAR files required for the OMERO.matlab toolbox
%
%   jarList = getOmeroJars() return a cell array containing the paths to
%   the JAR files necessary to use all the functionalities of the
%   OMERO.matlab toolbox.
%
% See also: LOADOMERO, UNLOADOMERO

% Copyright (C) 2014-2019 University of Dundee & Open Microscopy Environment.
% All rights reserved.
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

% Retrieve path to the toolbox libraries
libpath = fullfile(findOmero(), 'libs');

% Create a cell array with the dependency jars
files = dir(libpath);
L = length(files);
jarList = {};
javaPath = javaclasspath('-all');
for i=1:L
    name = strcat('.*', files(i).name, '$');
    has_jar = any(~cellfun(@isempty, regexp(javaPath, name,...
    'match', 'once')));
    if ~has_jar
        jar_file = fullfile(libpath, files(i).name);
        jarList = horzcat(jarList, {jar_file});
end

end
