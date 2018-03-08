function varargout = TunningPID(varargin)
% TUNNINGPID MATLAB code for TunningPID.fig
%      TUNNINGPID, by itself, creates a new TUNNINGPID or raises the existing
%      singleton*.
%
%      H = TUNNINGPID returns the handle to a new TUNNINGPID or the handle to
%      the existing singleton*.
%
%      TUNNINGPID('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TUNNINGPID.M with the given input arguments.
%
%      TUNNINGPID('Property','Value',...) creates a new TUNNINGPID or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TunningPID_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TunningPID_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TunningPID

% Last Modified by GUIDE v2.5 26-Mar-2017 15:14:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TunningPID_OpeningFcn, ...
                   'gui_OutputFcn',  @TunningPID_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before TunningPID is made visible.
function TunningPID_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TunningPID (see VARARGIN)
ComList = instrhwinfo('serial');
handles.COMports = ComList.AvailableSerialPorts;  %Cell variable
if( isempty(handles.COMports))
    set( handles.COMlistBox,'String','没有串口');
    set( handles.StartTempRegButton,'Enable','off');
    set( handles.ShutdownTempRegButton,'Enable','off');
    set(handles.CellTempSetButton,'Enable','off');
    set(handles.PrismTempSetButton,'Enable','off');
    set(handles.ReadPIDButton,'Enable','off');
    set(handles.SetPIDButton,'Enable','off');
    set(handles.ConnectButton,'Enable','off');
else
    set( handles.COMlistBox,'String',handles.COMports);
    set( handles.StartTempRegButton,'Enable','on');
    set( handles.ShutdownTempRegButton,'Enable','on');
    set(handles.CellTempSetButton,'Enable','on');
    set(handles.PrismTempSetButton,'Enable','on');
    set(handles.ReadPIDButton,'Enable','on');
    set(handles.SetPIDButton,'Enable','on');
    set(handles.ConnectButton,'Enable','on');
end

% 命令字
handles.StartMission = 6;
handles.ReadSystemTemp = 5; 
handles.ReadWaterboxTemp = 41;
handles.SetPIDParams = 11; % 本命令 + 1byte地址 + 12bytes PID参数
handles.ReadPIDParams = 12; % 本命令 + 1byte地址 ---返回---->12bytes PID参数



handles.Serial_TempCom=[];
handles.BaudRate = 115200;
handles.InputBufferSize = 10240;

handles.CellTemp = [];
handles.PrismTemp = [];
handles.WaterboxTemp = [];
handles.CellTempHist = [];
handles.PrismTempHist = [];
handles.WaterboxTempHist = [];
handles.TempTime=[];
set( handles.ShutdownTempRegButton , 'UserData' , 1 );
% Choose default command line output for TunningPID
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TunningPID wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TunningPID_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)d

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in ConnectButton.
function ConnectButton_Callback(hObject, eventdata, handles)
% hObject    handle to ConnectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if( isempty(handles.Serial_TempCom))
    val = get(handles.COMlistBox,'Value');
    ComNum = handles.COMports{val};
    SerialPort = serial( ComNum , 'BaudRate',handles.BaudRate, 'InputBufferSize', handles.InputBufferSize );
    fopen( SerialPort );
    set( handles.ConnectButton,'String','断开控制器');
    handles.Serial_TempCom = SerialPort;
else
    if( strcmp( handles.Serial_TempCom.Status,'open'))
        fclose( handles.Serial_TempCom);
    end
    set( handles.ConnectButton,'String','连接控制器');
end

guidata(hObject, handles);
% --- Executes on button press in CellTempSetButton.
function CellTempSetButton_Callback(hObject, eventdata, handles)
% hObject    handle to CellTempSetButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmp = inputdlg('输入温度值：','设定温度');
Temp = str2num( tmp{1} );
% 温度转化成ADC的值
setTemp = Temp2ADCVal( Temp );
Serial =handles.Serial_TempCom;
if( isempty( handles.PrismTemp ))
    setTemp_H = fix( setTemp / 256 );
    setTemp_L =fix( setTemp -setTemp_H*256 );
    fwrite( Serial , 3 , 'uint8');
    fwrite( Serial , setTemp_H , 'uint8');
    fwrite( Serial , setTemp_L , 'uint8');
    fwrite( Serial , setTemp_H , 'uint8');
    fwrite( Serial , setTemp_L , 'uint8');
else
    setTemp_H = fix( setTemp / 256 );
    setTemp_L =fix( setTemp -setTemp_H*256 );
    PrismTemp_H = fix(handles.PrismTemp/256);
    PrismTemp_L =fix( handles.PrismTemp - PrismTemp_H*256 );
    fwrite( Serial , 3 , 'uint8');
    fwrite( Serial , setTemp_H , 'uint8');
    fwrite( Serial , setTemp_L , 'uint8');    
    fwrite( Serial , PrismTemp_H , 'uint8');
    fwrite( Serial , PrismTemp_L , 'uint8');  
end

handles.CellTemp = setTemp;
guidata(hObject, handles);

% --- Executes on button press in PrismTempSetButton.
function PrismTempSetButton_Callback(hObject, eventdata, handles)
% hObject    handle to PrismTempSetButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmp = inputdlg('输入温度值：','设定温度');
Temp = str2num( tmp{1} );
% 温度转化成ADC的值
setTemp = Temp2ADCVal( Temp );
Serial =handles.Serial_TempCom;
if( isempty( handles.CellTemp ))
    setTemp_H = fix( setTemp / 256 );
    setTemp_L =fix( setTemp -setTemp_H*256 );
    fwrite( Serial , 3 , 'uint8');
    fwrite( Serial , setTemp_H , 'uint8');
    fwrite( Serial , setTemp_L , 'uint8');
    fwrite( Serial , setTemp_H , 'uint8');
    fwrite( Serial , setTemp_L , 'uint8');
else
    setTemp_H = fix( setTemp / 256 );
    setTemp_L =fix( setTemp -setTemp_H*256 );
    CellTemp_H = fix(handles.CellTemp/256);
    CellTemp_L =fix( handles.CellTemp - handles.CellTemp*256 );
    fwrite( Serial , 3 , 'uint8');
    fwrite( Serial , setTemp_H , 'uint8');
    fwrite( Serial , setTemp_L , 'uint8');    
    fwrite( Serial , CellTemp_H , 'uint8');
    fwrite( Serial , CellTemp_L , 'uint8');  
end
handles.PrismTemp = Temp2ADCVal( Temp );
guidata(hObject, handles);

% --- Executes on button press in SetPIDButton.
function SetPIDButton_Callback(hObject, eventdata, handles)
% hObject    handle to SetPIDButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Serial =handles.Serial_TempCom;
SetPIDCmd = 11;
tmp = inputdlg('输入要修改的值的地址：','设定地址');
addr = str2num( tmp{1} );tmp=[];
if( addr<8 )  % PID参数只有8组 0-7
    tmp = inputdlg('输入Kp值：','设定Kp');
    Kp = str2double( tmp{1} );tmp=[];
    if( Kp <65536 && Kp>0)
        tmp = inputdlg('输入Ki值：','设定Ki');
        Ki = str2double( tmp{1} );tmp=[];
        if( Ki <65536 && Ki>=0)
            tmp = inputdlg('输入Kd值：','设定Kd');
            Kd = str2double( tmp{1} );tmp=[];
            if( Kd>=0 && Kd<65536 )
                % 写入到Uno中
            Params = uint32(65536.*[ Kp , Ki , Kd ]);
            Params_HH = uint8( bitshift( bitand( Params , 4278190080) ,-24) );  % 0xff00 0000
            Params_H  = uint8( bitshift( bitand( Params ,  16711680), -16 ) );  % 0x00ff 0000
            Params_LL = uint8( bitshift( bitand( Params , 65280) , -8 ));       % 0x0000 ff00
            Params_L  = uint8( bitand( Params , 255 ) );                        % 0x0000 00ff
            ParamsToSend(1:4:9) = Params_HH;ParamsToSend( 2:4:10) = Params_H;
            ParamsToSend(3:4:11) = Params_LL; ParamsToSend(4:4:12) = Params_L;
            ParamsToSend=[ SetPIDCmd,addr , ParamsToSend ];
            for(i=1:1:length( ParamsToSend ))
                fwrite( Serial, ParamsToSend(i) , 'uint8');
            end
            else
                errordlg('输入的Kd值超出范围(0-4)'); 
            end
        else
            errordlg('输入的Ki值超出范围(0-4)'); 
        end
    else
       errordlg('输入的Kp值超出范围:(0-4)'); 
    end   
else
    errordlg('输入的地址不存在，请重新输入');
end

% --- Executes on button press in ReadPIDButton.
function ReadPIDButton_Callback(hObject, eventdata, handles)
% hObject    handle to ReadPIDButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Serial =handles.Serial_TempCom;
QueryKparam=12;
if( Serial.BytesAvailable)
    fread( Serial.BytesAvailable);
end
tmp = inputdlg('输入要读取的值的地址：','设定地址');
addr = str2num( tmp{1} );tmp=[];
if( addr <8) % PID参数只有8组 0-7
    fwrite( Serial , QueryKparam , 'uint8');
    fwrite( Serial , addr , 'uint8');
    while( 18>Serial.BytesAvailable )
    end
    Kparam = fread( Serial , Serial.BytesAvailable);
    Kparam = char( Kparam');
    disp(Kparam);
else 
    errordlg('输入的地址不存在，请重新输入');
end
% --- Executes on button press in ShutdownTempRegButton.
function ShutdownTempRegButton_Callback(hObject, eventdata, handles)
% hObject    handle to ShutdownTempRegButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set( handles.ShutdownTempRegButton , 'UserData' , 0 );
fwrite( handles.Serial_TempCom , 0 ,'uint8');
handles.CellTempHist = [];
handles.PrismTempHist= [];
handles.TempTime = [];
cla( handles.CellTempAxis);
cla( handles.PrismTempAxis);
guidata(hObject, handles);
% --- Executes on selection change in COMlistBox.
function COMlistBox_Callback(hObject, eventdata, handles)
% hObject    handle to COMlistBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns COMlistBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from COMlistBox


% --- Executes during object creation, after setting all properties.
function COMlistBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to COMlistBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if( ~isempty(handles.Serial_TempCom))
    if( strcmp( handles.Serial_TempCom.Status,'open'))
        fclose( handles.Serial_TempCom);
    end
end
% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in StartTempRegButton.
function StartTempRegButton_Callback(hObject, eventdata, handles)
% hObject    handle to StartTempRegButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% handles.StartMission = 6; 
% handles.ReadSystemTemp = 5;  % 本命令 ---返回---->2*3 bytes字节
% handles.ReadWaterboxTemp = 41;
% handles.SetPIDParams = 11; % 本命令 + 1byte地址 + 12bytes PID参数
% handles.ReadPIDParams = 12; % 本命令 + 1byte地址 ---返回---->12bytes PID参数

% handles.Serial_TempCom=[];
% handles.CellTemp = [];
% handles.PrismTemp = [];
% handles.WaterboxTemp = [];
% handles.CellTempHist = [];
% handles.PrismTempHist = [];
% handles.WaterboxHist = [];
% handles.TempTime=[];

handles.CellTempHist = [];
handles.PrismTempHist= [];
handles.WaterboxTempHist = [];
handles.TempTime = [];

cla( handles.CellTempAxis);
cla( handles.PrismTempAxis);
cla( handles.WaterboxTempAxis );

set( handles.ShutdownTempRegButton , 'UserData' , 1 );

fwrite( handles.Serial_TempCom , 6 ,'uint8');
while(1)
    disp('I run into while, waiting for temperature');
    Temperature = ReadTemp( handles.Serial_TempCom , handles.ReadSystemTemp);
    if( Temperature(1)>40 || Temperature(2)>40 || Temperature(3)>40 || Temperature(1)<12 || Temperature(2)<12|| Temperature(3)<12 )
        fwrite( handles.Serial_TempCom , 0 ,'uint8');%高温/低温保护
    end
    handles.CellTempHist = [ handles.CellTempHist , Temperature(1)];
    handles.PrismTempHist= [ handles.PrismTempHist , Temperature(2)];
    handles.WaterboxTempHist = [ handles.WaterboxTempHist , Temperature(3)];
    %handles.TempTime = [ handles.TempTime , handles.TempTime(length(handles.TempTime))+0.1];
    plot( handles.CellTempAxis , handles.CellTempHist );
    plot( handles.PrismTempAxis, handles.PrismTempHist );
    plot( handles.WaterboxTempAxis, handles.WaterboxTempHist );
    if(~get(handles.ShutdownTempRegButton,'UserData'))
        fwrite( handles.Serial_TempCom , 0 ,'uint8');
        tim = clock();
        FolderName = sprintf( 'Time%d%d_%d%d',  tim(2:5));
        SavePath = [ pwd,'\',FolderName ];
        mkdir( SavePath );   
        SavePath = [ SavePath ,'\'];
        CellTemp = handles.CellTempHist;
        PrismTemp = handles.PrismTempHist;
        WaterBoxTemp = handles.WaterboxTempHist;
        save( [ SavePath 'Temperature' ]  , 'CellTemp', 'PrismTemp', 'WaterBoxTemp');
        break;
    end
    pause(0.1)
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
