%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) 2011-2014 by the Human Connectome Project, WU-Minn Consortium (1U54MH091657)
%
% This file is part of megconnectome.
%
% megconnectome is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% megconnectome is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with megconnectome.  If not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% setup the execution environment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ensure that the time and date of execution are not stored in the provenance information
opengl software;


% ensure that the time and date of execution are not stored in the provenance information
global ft_default
ft_default.trackcallinfo = 'no';

% allow the user to specify the path where additional data is present, e.g. the channel layout or anatomy files
if exist('path', 'var')
    addpath(path)
end

%% INPUT
% Here 2 filenames are required for Working Memory and Story Math and 1 for
% Motor. So there are 2 variables

if ~exist('filename1', 'var')
    error('filename1 at least should be specified')
end

if ~exist('filename2', 'var')
    filename2='';
end

% the filename is assumed to be something like
% 'rawdatadir/Phase1MEG/Subjects/CP10018/Experiments/CP10018_MEG/Scans/1-Rnoise_MNN_V1/Resources/4D/c,rfDC'

tokF1 = tokenize(filename1, '/'); if ~isempty(filename2), tokF2 = tokenize(filename2, '/');end;

if ~exist('experimentid', 'var')
    experimentid1 = tokF1{end-4};
    if ~isempty(filename2),
        experimentid2 = tokF2{end-4};
        if ~strcmp(experimentid1,experimentid2),
            error('the two filenames provided have different experimentid');
        else
            experimentid=experimentid1;
        end
    else
        experimentid=experimentid1;
    end
end



if ~exist('subjectid', 'var')
    dumInd=regexp(experimentid,'_MEG');
    subjectid1 = experimentid(1:dumInd-1);
    if ~isempty(filename2),
        dumInd=regexp(experimentid,'_MEG');
        subjectid2 = experimentid(1:dumInd-1);
        
        if ~strcmp(subjectid1,subjectid2),
            error('the two filenames provided are from different subjects');
        else
            subjectid=subjectid1;
        end
    else
        subjectid=subjectid1;
    end
end

%--------------------------------
%------------------------------------------------
if ~exist('scanid1', 'var')
    scanid1 = tokF1{end-2};
end
tmptok1         = tokenize(scanid1, '-');
scanmnem1     = tmptok1{2};
%------- The following is just for the cases where the suffix "_Run1 or
%Run2" has been added to the scanid in order to differentiate between 2
%different runs of the same paradigm. i.e. The way Robert has saved data in
%his database for subject CP10168.
indRunStr=regexp(scanmnem1,'_Run');
if ~isempty(indRunStr),
    scanmnem1=scanmnem1(1:indRunStr(1)-1);
end


if ~exist('scanid2', 'var')
    if ~isempty(filename2),
        scanid2 = tokF2{end-2};
    else
        scanid2='';
    end
end
if ~isempty(scanid2)
    tmptok2         = tokenize(scanid2, '-');
    scanmnem2     = tmptok2{2};
    %------- The following is just for the cases where the suffix "_Run1 or
    %Run2" has been added to the scanid in order to differentiate between 2
    %different runs of the same paradigm. i.e. The way Robert has saved data in
    %his database for subject CP10168.
    indRunStr=regexp(scanmnem2,'_Run');
    if ~isempty(indRunStr),
        scanmnem2=scanmnem2(1:indRunStr(1)-1);
    end
else
    scanmnem2='';
end;
%------------------------------------------------
%--------------------------------
if ~isempty(scanmnem2)
    if ~strcmp(scanmnem1,scanmnem2)
        error('the two scan mnemonics do not seem to agree');
    end
end
scanmnem=scanmnem1;

if ~exist('anatomydir', 'var')
    disp('No anatomydir provided - Assuming is in experimentid/Resources/anatomy/');
    indExpStr=regexp(filename1,experimentid);
    anatomydir=[filename1(1:indExpStr-1),experimentid,'/RESOURCES/anatomy/'];
    %error('No anatomy directory was provided. Anatomical information is required for this pipeline.');
end

% Check if anatomy files are present
dummysubjid=[anatomydir,subjectid]; % TODO! This is a temporary solution because the hcp_checkpipeoutput for anatomy assume that the files are always in the current directory
%hcp_check_pipelineoutput('anatomy', 'subject', dummysubjid);

if ~exist('srcgridtype', 'var')
    srcgridtype='3D';
end

if ~exist('datagroupstr', 'var')
    datagroupstr=[];
end

if ~exist('contrastidstr', 'var')
    contrastidstr=[];
end

if ~exist('freqbandstr', 'var')
    freqbandstr='';
end

if ~exist('connemetricstr', 'var')
    connemetricstr='';
end

if ~exist('pipelinedatadir', 'var')
    pipelinedatadir = hcp_pathdef;
end
if ~exist('savedir', 'var')
    if strcmp(pipelinedatadir(end),'/')
        savedir=pipelinedatadir;
    else
        savedir=[pipelinedatadir,'/'];
    end
end

if ~exist('beamflambda','var')
    %beamflambda='100%';
    error('The beamformer lambda has not been set');
else
    if ischar(beamflambda)
        beamflambda=str2num(beamflambda);
        if isempty(beamflambda)
            error('There is a problem with the beamformer lambda set by the user');
        end
        beamflambda=[num2str(beamflambda),'%'];
    elseif isnumeric(beamflambda)
        beamflambda=[num2str(beamflambda),'%'];
    end
end


% print the matlab and megconnectome version to screen for provenance
ver('megconnectome')

% print the value of all local variables to screen for provenance
%{
w = whos;
w = {w.name};
w = setdiff(w, {'w', 'ans'});
for i=1:length(w)
    fprintf(hcp_printstruct(w{i}, eval(w{i})));
end
%}
% change to the location of the processed data (input and output)
cd(pipelinedatadir)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% execute the pipeline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%======================================================
%% THOROUGH CHECKS OF INPUTS BEFORE ANALYSIS

Nfiles=1+(~isempty(filename2));

%================================
% Should this stop the pipeline?
if Nfiles==1,
    if (~isempty( strfind( scanid1 , 'Wrkmem' ) ))|(~isempty( strfind( scanid1 , 'StoryM' )))
        disp('WARNING!!! Only 1 file provided for Working memory or Story Math');
    end
end
%================================
contrastid=tokenize(contrastidstr, ',');
if isempty(contrastid{1})
    contrastid='';
end

datagroupid=tokenize(datagroupstr, ',');
if isempty(datagroupid{1})
    datagroupid='';
end
connemetricid=tokenize(connemetricstr, ',');
if isempty(connemetricid{1})
    connemetricid='';
end
if (~isempty(contrastid))&(~isempty(datagroupid))
    error('Both constrast and datagroup have been provided. The contrastid contains the datagroupid aswell');
end

%--------
freqbandid=tokenize(freqbandstr, ',');
if isempty(freqbandid{1})
    freqbandid='';
end
if (~isempty(contrastid))&(~isempty(freqbandid))
    error('Both constrast and freq. bands have been provided. The contrastid contains the freqbandid aswell');
end





resultprefix = sprintf('%s_%s', experimentid, scanmnem);
savesuffix_general='srcconnebasic';

% the location of the dataset, i.e. the c,rfDC file with full path

%=========================================
%-- Load all contrasts lists
contrastfun   = ['contrast_', scanmnem];
%------------------
for iFile=1:Nfiles,
    eval(['scanid=scanid',num2str(iFile)]);
    hcp_check_pipelineoutput('tmegpreproc', 'subject', subjectid, 'experiment', experimentid, 'scan', scanid); % Checking for trialinfo only
    inputTrialInfoFile        = sprintf('%s_%s_tmegpreproc_trialinfo',experimentid, scanid);
    hcp_read_matlab(inputTrialInfoFile,'trlInfo');
    
    
    eval(['cntrstList{iFile}=',contrastfun,'(trlInfo)']);
end
%--------------------------------------------
% CHeck that the 2 all contrast lists have the same number of contrasts
% and extract all the datagroupids

Nallcontr1=length(cntrstList{1});
callnames1=[];
pipenames=[];
for iC=1:Nallcontr1,
    callnames1{iC}=cntrstList{1}{iC}.mnemprint;
    pipenames{iC}=cntrstList{1}{iC}.pipeline;
end
if Nfiles==2,
    Nallcontr2=length(cntrstList{2});
    if Nallcontr1~=Nallcontr2
        error('The two files do not have the same number of contrasts in their all contrast lists');
    end
    
    callnames2=[];for iC=1:Nallcontr2, callnames2{iC}=cntrstList{2}{iC}.mnemprint;end
end
%-----------Find only the contrasts that are flagged for this pipeline
[indxPipe,ind2]=match_str(pipenames,'tmegconne');

if isempty(indxPipe)
    error('No srcavgdics constasts were found in the allcontrast list');
else
    curPipecntrList{1}=cntrstList{1}(indxPipe);
    curPipecallnames=callnames1(indxPipe);
    if Nfiles==2,
        curPipecntrList{2}=cntrstList{2}(indxPipe);
    end
end
curPipeBandNames=[];
for iA=1:length(curPipecntrList{1})
    curPipeBandNames{iA}=curPipecntrList{1}{iA}.freqband;
end

Nsrcavgdicscontr=length(curPipecntrList{1});
%--- End of checking the all contrast list
%-------------------------------------------------------
%=======================================================================
%=======================================================================
%=======================================================================
%% FUSE all contrasts list with inputs (if present otherwise use all contrasts)
procCntrList=[];
if ~isempty(contrastid)
    NcontrIn=length(contrastid);
    [indAll,indIn]=match_str(curPipecallnames,contrastid);
    if length(indIn)~=NcontrIn
        error(['Some contrast from the provided input were not found ']);
    end
    procCntrList{1}=curPipecntrList{1}(indAll);
    procCntrNames=curPipecallnames(indAll);
    procCntrBandNames=curPipecallnames(indAll);
    if Nfiles==2,
        procCntrList{2}=curPipecntrList{2}(indAll);
    end
else
    if isempty(datagroupid)
        procCntrList=curPipecntrList;
        procCntrNames=curPipecallnames;
        procCntrBandNames=curPipeBandNames;
    else
        procCntrList=[];
        procCntrNames=[];
        procCntrBandNames=[];
        countCntr=1;
        for iC=1:Nsrcavgdicscontr
            iGr=1;
            while iGr<=length(datagroupid)
                
                if  strcmp(curPipecntrList{1}{iC}.lockmode,datagroupid{iGr})
                    procCntrList{1}{countCntr}=curPipecntrList{1}{iC};
                    procCntrNames{countCntr}=curPipecallnames{iC};
                    procCntrBandNames{countCntr}=curPipeBandNames{iC};
                    if Nfiles==2,
                        procCntrList{2}{countCntr}=curPipecntrList{2}{iC};
                    end
                    countCntr=countCntr+1;
                    iGr=length(datagroupid)+1;
                else
                    iGr=iGr+1;
                end
            end
        end
        
        
        
    end
    if ~isempty(freqbandid)
        tmpprocCntrList=[];
        tmpprocCntrNames=[];
        tmpprocCntrBandNames=[];
        countCntr=1;
        for iC=1:length(procCntrBandNames)
            iFB=1;
            while iFB<=length(freqbandid)
                
                if  strcmp(procCntrBandNames(iC),freqbandid{iFB})
                    tmpprocCntrList{1}{countCntr}=procCntrList{1}{iC};
                    tmpprocCntrNames{countCntr}=procCntrNames{iC};
                    tmpprocCntrBandNames{countCntr}=procCntrBandNames{iC};
                    if Nfiles==2,
                        tmpprocCntrList{2}{countCntr}=procCntrList{2}{iC};
                    end
                    countCntr=countCntr+1;
                    iFB=length(freqbandid)+1;
                else
                    iFB=iFB+1;
                end
            end
            
            
        end
        procCntrList=tmpprocCntrList;
        procCntrNames=tmpprocCntrNames;
        procCntrBandNames=tmpprocCntrBandNames;
    end
    
    if isempty(connemetricid)
        procCntrList=curPipecntrList;
        procCntrNames=curPipecallnames;
        procCntrBandNames=curPipeBandNames;
    else
        procCntrList=[];
        procCntrNames=[];
        procCntrBandNames=[];
        countCntr=1;
        for iC=1:Nsrcavgdicscontr
            iGr=1;
            while iGr<=length(connemetricid)
                
                if  strcmp(curPipecntrList{1}{iC}.connemetric,connemetricid{iGr})
                    procCntrList{1}{countCntr}=curPipecntrList{1}{iC};
                    procCntrNames{countCntr}=curPipecallnames{iC};
                    procCntrBandNames{countCntr}=curPipeBandNames{iC};
                    if Nfiles==2,
                        procCntrList{2}{countCntr}=curPipecntrList{2}{iC};
                    end
                    countCntr=countCntr+1;
                    iGr=length(connemetricid)+1;
                else
                    iGr=iGr+1;
                end
            end
        end
        
        
        
    end
    
    
    
end
%----
if isempty(procCntrList)
    procCntrList=curPipecntrList;
    procCntrNames=curPipecallnames;
    procCntrBandNames=curPipeBandNames;
end

%--- END OF constructing the contrast list
%==========================================================================
%--- END OF checking phase before analysis
%==========================================================================
%==========================================================================
%==========================================================================
%-- Check if tfsens data is available for the data groups involved
Nproccontr=length(procCntrNames);
procGroups=[];
for iC=1:Nproccontr,
    procGroups=unique([procGroups,procCntrList{1}{iC}.lockmode]);
end
%{
for iGr=1:length(procGroups)
    curGroup=procGroups{iGr};
    curBands=[];
    for iC=1:Nproccontr
        if strcmp(procCntrList{1}{iC}.lockmode,curGroup)
            curBands=[curBands procCntrBandNames(iC)];
        end
    end
    if ~isempty(curBands)
        curBands=unique(curBands);
%        hcp_check_pipelineoutput('tfsens', 'subject', subjectid, 'experiment', experimentid, 'scan', scanid1,'datagroup',curGroup,'band',curBands);
        if Nfiles==2,
 %           hcp_check_pipelineoutput('tfsens', 'subject', subjectid, 'experiment', experimentid, 'scan', scanid2,'datagroup',curGroup,'band',curBands);
        end
    else
        warning('No contrasts were found');
    end
end
%}
%============================================================

% bandDef={'D',   [1 3]
%     'TH',  [4 7]
%     'A',   [8 14]
%     'Blow',[15 25]
%     'Bhigh',[26 34]
%     'Glow',[35 49]
%     'Gmid',[50 75]
%     'Ghigh', [76 120]};


bandDef={'delta' [1 4]
    'theta' [4 8]
    'alpha' [8 15]
    'betalow' [15 26]
    'betahigh' [26 35]
    'gammalow' [35 50]
    'gammamid' [50 76]
    'gammahigh' [76 120]};


%{
bandDef={'D1',   [1 3]
         'D2',   [2 4]
         'TH1',  [3 6]
         'TH2',  [4 7]
         'A1',   [6 11]
         'A2',   [8 13]
         'A3',   [10 15]
         'B1',   [12  18]
         'B2',   [15  23]
         'B3',   [20  28]
         'B4',   [25  35]
         'G1',   [30  40]
         'G2',   [35  50]
         'G3',   [45  60]
         'G4',   [55  75]
         'G5',   [65  85]
         'G6',   [75  95]
         'G7',   [85  110]};
    %}
    %==========================================================================
    % procCntrList;
    % procCntrNames;
    % procGroups;
    
    if Nfiles==1,
        multiscanid={scanid1};
    elseif Nfiles==2,
        multiscanid={scanid1 scanid2};
    end
    %
    %{
      allprocCntrList= procCntrList;
      procCntrList{1}=allprocCntrList{1}(22);
      procCntrList{2}=allprocCntrList{2}(22);
    %}
    
    cfg = [];
    cfg.contrastlist   =  procCntrList;
    cfg.subjectid      =  subjectid;
    cfg.experimentid   =  experimentid;
    cfg.multiscanid    =  multiscanid;
    cfg.bandinfo       =  bandDef;
    cfg.anatomydir    = anatomydir;
    cfg.gridtype      = srcgridtype;
    cfg.savedir       = savedir;
    cfg.beamflambda   = beamflambda;
    
    [outStatus] = hcp_tmegconnebasic_contrasts(cfg);
    
    % hcp_check_pipelineoutput('srcavgdics', 'subject', subjectid, 'experiment', experimentid, 'scan', scanmnem,'avgmode',avgmode,'contrasts',procCntrNames);
    
    
