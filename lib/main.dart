import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';


import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(const Size(1619, 900));
    setWindowMaxSize(Size.infinite);
  }


  runApp(MyApp());
}

enum ProgramState { None,FileSelected,Processing,Success,Failed}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(brightness: Brightness.dark,elevatedButtonTheme: ElevatedButtonThemeData(style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.black26)))),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }



  StreamController<String> _outputController = new StreamController<String>();
  List<String> _textList = [];
  ScrollController _scrollController = ScrollController();
  File? Ffile;
  FilePickerResult? FPResult;
  String BundleInputPath='';


  ProgramState TheState=ProgramState.None;
  @override
  void dispose() {
    _outputController.close();
    _scrollController.dispose();
    super.dispose();
  }


  Future<void> runJavaCommand() async {
    try {
      _textList.clear();
      _outputController.close();
      _outputController=new StreamController();
      setState(() {
        TheState=ProgramState.Processing;
      });
      


      // Build the command
      String command = 'java -jar MergingTool/APKE.jar m -i $BundleInputPath';

      // Run the command
      Process result = await Process.start(command,[], runInShell: true);

      
// Listen to the standard output stream
      result.stdout.transform(utf8.decoder).listen((data) {
        _outputController.add(data); // Update the output text
      });
      result.stderr.transform(utf8.decoder).listen((event) {
        _outputController.add(event);
      });
      // Wait for process to complete
      int exitCode = await result.exitCode;
      _outputController.close();

      // Handle the result as needed
      if (exitCode == 0) {
        // Command executed successfully
        //print('Command executed successfully');
        setState(() {
          TheState=ProgramState.Success;
          _textList.clear();
          _textList.add('Merge Completed: ${basenameWithoutExtension(Ffile!.path)}_merged.apk has been created');
          _textList.add('OUTPUT: ${Ffile!.path.split('\\').sublist(0, Ffile!.path.split('\\').length - 1).join('\\')}\\${basenameWithoutExtension(Ffile!.path)}_merged.apk');
        });
      } else {
        // Command failed
        setState(() {
          TheState=ProgramState.Failed;
          _textList.clear();
          _textList.add('Command failed with exit code: $exitCode');
        });
        //print('Command failed with exit code: $exitCode');
      }
    } catch (error) {
      // Handle any exceptions
      //print('Error: $error');
      setState(() {
        TheState=ProgramState.Failed;
        _textList.clear();
        _textList.add('Command failed with error: $error');
      });
    }
  }

  String isNonEmptyString(String input) {
    // Remove all spaces from the input string
    String stringWithoutSpaces = input.replaceAll('  ', '');

    // Check if the resulting string is empty
    return stringWithoutSpaces;
  }

  Widget GetMyIcon()
  {

    Widget R= Container(width: 10,height: 10,);
    switch(TheState)
    {
      case ProgramState.None:
        break;
      case ProgramState.FileSelected:
        R=const Icon(Icons.folder,color: Colors.orangeAccent,size: 200,);
        break;
      case ProgramState.Processing:
        R=const SizedBox(width: 180,height: 180, child: CircularProgressIndicator(strokeWidth: 15,));
        break;
      case ProgramState.Success:
        R=const Icon(Icons.check,color: Colors.green,size: 200,);
        break;
      case ProgramState.Failed:
        R=const Icon(Icons.close,color: Colors.red,size: 200,);
        break;
    }
    return R;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black54,
              child: Stack(
                children: [
                  StreamBuilder<String>(
                    stream: _outputController.stream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        if(TheState!=ProgramState.Success)
                        {
                          String T=isNonEmptyString(snapshot.data!);
                          if(T.isNotEmpty)
                          {
                            _textList.add(T);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                            });
                          }
                        }

                      }
                      return ListView.builder(
                          controller: _scrollController,
                          itemCount: _textList.length,
                          itemBuilder: (context,index){
                            return ListTile(title: Text(_textList[index],style: TextStyle(color: Colors.white38),),);
                          });
                    },
                  ),
                  if(TheState==ProgramState.Failed || TheState==ProgramState.Success) Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            String Clp=_textList.toString().substring(1, _textList.toString().length - 1);
                            await Clipboard.setData(ClipboardData(text: Clp));
                          },
                          child: const Text('Copy'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  enabled: false,
                                  decoration: InputDecoration(  border: OutlineInputBorder(),  labelText: BundleInputPath.length == 0 ? 'Pick a file':'$BundleInputPath'),
                                ),
                              ),
                              width: 500,
                            ),
                            SizedBox(
                              width: 120,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    if(TheState==ProgramState.Processing)
                                    {
                                      return;
                                    }
                                    FPResult = await FilePicker.platform.pickFiles();
                                    if (FPResult != null) {

                                      setState(() {
                                        Ffile=File(FPResult!.files.single.path!);
                                        BundleInputPath=Ffile!.path;
                                        TheState=ProgramState.FileSelected;
                                      });
                                    } else {
                                      setState(() {
                                        BundleInputPath='';
                                        TheState=ProgramState.None;
                                      });
                                    }
                                  } catch (_) {
                                    setState(() {
                                      BundleInputPath='';
                                      TheState=ProgramState.None;
                                    });
                                  }
                                },
                                child: const Text('Browse'),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 150,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () async {
                                if(!BundleInputPath.isNotEmpty)
                                {
                                  return;
                                }
                                if(TheState!=ProgramState.FileSelected)
                                {
                                  return;
                                }
                                if(BundleInputPath.isNotEmpty && TheState==ProgramState.FileSelected)
                                {
                                  setState(() {
                                    _textList.clear();
                                  });
                                  runJavaCommand();
                                }
                                else{
                                  setState(() {
                                    BundleInputPath='';
                                    TheState=ProgramState.None;
                                  });
                                }

                              },
                              child: const Text('Start Merge'),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        child: GetMyIcon(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
