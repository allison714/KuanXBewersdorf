function link = linkAnnotation(session, annotation, parentType, parentId)
% LINKANNOTATION Link an annotation to an object on the OMERO server
%
%    fa = linkAnnotation(session, annotation, parentType, parentId) creates
%    a link between the input annotation to the object of the input type
%    specified by the input identifier and owned by the session user.
%
%
% SYNTAX
% link = linkAnnotation(session, annotation, parentType, parentId)
%
% INPUT ARGUMENTS
% session     omero.api.ServiceFactoryPrxHelper object
%
%               client = loadOmero('demo.openmicroscopy.org', 4064)
%               session = client.createSession(username, password)
%
%
% annotation  an omero.model.Annotation object 
%             
% parentType  'project' | 'dataset' | 'image' | 'screen' | 'plate' |
%             'plateacquisition' | 'roi'
%             Depends on output of getObjectTypes()
%
% parentId    a scalar or vector positive integers
%             Id numbers of parent objects.
%
%
% OUTPUT ARGUMENTS
% link       omero.model.ImageAnnotationLinkI object 
%
% See also

% Copyright (C) 2013-2019 University of Dundee & Open Microscopy Environment.
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

% Input check
objectTypes = getObjectTypes();
objectNames = {objectTypes.name};
ip = inputParser;
ip.addRequired('session');
ip.addRequired('annotation', @isscalar);
ip.addRequired('parentType', @(x) ischar(x) && ismember(x, objectNames));
ip.addRequired('parentId', @(x) isempty(x) || (isvector(x) && isnumeric(x)));
ip.parse(session, annotation, parentType, parentId);
objectType = objectTypes(strcmp(parentType, objectNames));

% Throw exception if type is roi
assert(~strcmp(objectType.class, 'omero.model.Roi'),...
    ['Cannot link annotations to rois. ']);

% Get the parent object
if isnumeric(parentId)
    assert(~isempty(parentId), 'No %s specified', parentType);
    parent = getObjects(session, parentType, parentId);
    assert(~isempty(parent), 'No %s with id %g found', parentType, parentId);
else
    parent = parentId;
end

for i = 1:numel(parent)
    % Create object annotation link
    context = java.util.HashMap;
    group = parent(i).getDetails().getGroup().getId().getValue();
    context.put('omero.group', java.lang.String(num2str(group)));
    
    link = objectType.annotationLink();
    link.setParent(parent(i))
    link.setChild(annotation);
    link = session.getUpdateService().saveAndReturnObject(link, context);

end
