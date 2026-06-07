function validate_ui_smoke()
%VALIDATE_UI_SMOKE Fast launch check for the Intelligent Navigation UI.
% This script runs figures invisibly, deletes them before exit, and writes an
% OK/FAIL marker for repeatable Octave validation on Windows.

baseDir = fileparts(mfilename('fullpath'));
logDir = fullfile(baseDir, 'validation', 'logs');
if exist(logDir, 'dir') ~= 7
    mkdir(logDir);
end

okFile = fullfile(logDir, 'ui_smoke.ok');
failFile = fullfile(logDir, 'ui_smoke.fail');
if exist(okFile, 'file') == 2
    delete(okFile);
end
if exist(failFile, 'file') == 2
    delete(failFile);
end

try
    oldDir = pwd;
    oldFigureVisible = get(0, 'defaultfigurevisible');
    set(0, 'defaultfigurevisible', 'off');
    cd(baseDir);
    mainText = fileread(fullfile(baseDir, 'main.m'));
    if isempty(strfind(mainText, 'RunIntelligentNavigationUI'))
        error('main.m does not call RunIntelligentNavigationUI.');
    end
    RunIntelligentNavigationUI();
    delete(findall(0, 'type', 'figure'));
    drawnow;
    set(0, 'defaultfigurevisible', oldFigureVisible);
    cd(oldDir);

    fid = fopen(okFile, 'w');
    fprintf(fid, 'UI_SMOKE_OK\n');
    fprintf(fid, 'main.m launched RunIntelligentNavigationUI without a thrown exception.\n');
    fclose(fid);
    disp('UI_SMOKE_OK');
catch err
    try
        delete(findall(0, 'type', 'figure'));
        drawnow;
        set(0, 'defaultfigurevisible', oldFigureVisible);
    catch
    end
    baseDir = fileparts(mfilename('fullpath'));
    logDir = fullfile(baseDir, 'validation', 'logs');
    failFile = fullfile(logDir, 'ui_smoke.fail');
    if exist(logDir, 'dir') ~= 7
        mkdir(logDir);
    end
    try
        cd(baseDir);
    catch
    end
    fid = fopen(failFile, 'w');
    fprintf(fid, 'UI_SMOKE_FAIL\n');
    fprintf(fid, '%s\n', err.message);
    fclose(fid);
    rethrow(err);
end
end
