function T = editChannelNames(session,img,varargin)
% editChannelNames allows you to change Channel Names for an image in OMERO
% server.
%
% SYNTAX
% T = editChannelNames(session,img)
% T = editChannelNames(session,img,newchannelNames)
% T = editChannelNames(session,'Param',value)
%
% T = editChannelNames(session,img) returns the current channel names. If
% not specified yet, they will be empty characters, although it may look
% like 0, 1, or 2 etc. on OMERO GUI since in that case the index of the channel
% is used.
%
% T = editChannelNames(session,img,newchannelNames) will set the channel names
% to newchannelNames.
%
% INPUT ARGUMENTS
% session     omero.api.ServiceFactoryPrxHelper object
%
% img         positive integer | omero.model.ImageI object
%             An Image ID or an omero.model.ImageI object for OMERO.
%
% newchannelNames
%             cell vector of character vectors | string vector
%             The new channel names. If you specify 'channelIndexes', the
%             length of channelIndexes and that of newchanNames must tally.
%
% OPTIONAL PARAMETER/VALUE PAIRS
% 'channelIndexes'
%             [] | vector of positive integers
%             (Optional) Channel indexes for specific editing. If you specify
%             'channelIndexes', the length of channelIndexes and that of
%             newchannelNames must tally.
%
% OUTPUT ARGUMENTS
% T           table array
%             With variables, 'Id', 'Name', and, if newchannelNames is
%             specified, 'NewName'.
%
% Written by Kouichi C. Nakamura Ph.D.
% MRC Brain Network Dynamics Unit
% University of Oxford
% kouichi.c.nakamura@gmail.com
% 10-Jul-2018 12:04:46
%
% See also
% loadChannels, getImages

p = inputParser;
p.addRequired('session',@(x) isscalar(x));
p.addRequired('img',@(x) isscalar(x));
p.addOptional('newchannelNames',[],@(x) isvector(x) && iscellstr(x) || isstring(x));
p.addParameter('channelIndexes',[],@(x) isvector(x) && all(fix(x) == x & x > 0));

p.parse(session,img,varargin{:});

newchanNames = p.Results.newchannelNames;
channelIndexes = p.Results.channelIndexes;

if ~isempty(channelIndexes)
    
    assert(length(channelIndexes) == length(newchanNames),...
        'When you specify channelIndexes, the length of channelIndexes and newchannelNames must tally.') 
    
end

if isstring(newchanNames)
    newchanNames = cellstr(newchanNames);
end


if isnumeric(img)

    img_ = img;

    img = getImages(session,img_);

end


channels = loadChannels(session, img);

channelIndex = zeros(numel(channels),1);
channelName = cell(numel(channels),1);
channelName_ = cell(numel(channels),1);


import java.util.ArrayList
li = ArrayList;

j = 0;
n = numel(channels);

for i = 1:n
    ch = channels(i);
    channelIndex(i,1) = double(i);
    if ~isempty(ch.getLogicalChannel().getName())
    
        channelName{i,1} = char(ch.getLogicalChannel().getName().getValue()); %java.lang.String

    else
        
        channelName{i,1} ='';
        
    end
    if ~isempty(newchanNames)
        if isempty(channelIndexes) || ismember(channelIndex(i,1),channelIndexes)
            j = j + 1;
            ch.getLogicalChannel().setName(rstring(newchanNames{j})); % overwrite
            channelName_{i,1} = char(ch.getLogicalChannel().getName().getValue());
        else
            channelName_{i,1} = channelName{i,1};
            
        end 
    end
    
    li.add(ch);
end


if ~isempty(newchanNames)
    T = table(channelIndex,channelName,channelName_,'VariableNames',{'Index','Name','NewName'});

    cs = session.getContainerService();
    cs.updateDataObjects(li,[]);% tricky to find the right type. see https://www.openmicroscopy.org/community/viewtopic.php?f=6&t=8536
    
else
    T = table(channelIndex,channelName,'VariableNames',{'Index','Name'});
end


end
