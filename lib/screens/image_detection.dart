import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class StaticImage extends StatefulWidget {
  @override
  _StaticImageState createState() => _StaticImageState();
}

class _StaticImageState extends State<StaticImage> {

  XFile? image;
  ImagePicker picker = ImagePicker();
  Map<String, dynamic>? responseJsonData;
  Map<String, dynamic>? responseJsonText;

  String apiKey = "";

  void _pickImage(int i, bool isImage) async {

    image = await picker.pickImage(source: i == 0 ?ImageSource.gallery : ImageSource.camera);

    final bytes = File(image!.path).readAsBytesSync();
    String base64Image =  base64Encode(bytes);

    if(image != null) {
      getDetails(base64Image, isImage);
    }

  }

  List imgLabel = [];
  String? result;

  getDetails(String s, bool isImage) async{

    setState(() {
      responseJsonData = null;
      responseJsonText = null;
      result = null;
    });

    try {

      final response = await http.post(
        Uri.parse("https://vision.googleapis.com/v1/images:annotate?key=$apiKey"),

        body: jsonEncode(<String, dynamic>{
          "requests":[
            {
              "image":{
                "content":s,
              },
              "features":[
                {
                  "type":
                  isImage == true ?
                  "LABEL_DETECTION" : "TEXT_DETECTION",
                  "maxResults":10
                }
              ]
            }
          ]
        }),
      );

      print(json.decode(response.body));

      if (response.statusCode == 200) {
        setState(() {
          isImage == true ?
          responseJsonData = json.decode(response.body) :
          responseJsonText = json.decode(response.body);
        });
      }else{
        print("Nooooooo");
      }

    } on Exception catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double mediaQH = MediaQuery.of(context).size.height;
    double mediaQW = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Image Detection"),
      ),
      body: Stack(

        children: [

          Container(
            height: mediaQH,
            width: mediaQW,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                SizedBox(height: mediaQH*0.05,),

                result == null ?

                image != null ?

                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    GestureDetector(
                      onTap:(){
                        print(responseJsonText);
                      },
                      child: Container(
                          height: mediaQW*0.8,
                          width: mediaQW*0.8,
                          child: Image.file(File(image!.path),fit: BoxFit.contain,)),
                    ),

                    SizedBox(height: mediaQH*0.025,),

                    responseJsonData != null  || responseJsonText != null ?

                    responseJsonData != null ?
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: ListView.builder(
                        itemCount: responseJsonData!["responses"][0]["labelAnnotations"].length,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        physics: BouncingScrollPhysics(),
                        itemBuilder: (context,index){
                          return Padding(
                            padding: const EdgeInsets.all(1.0),
                            child: Container(
                              width: mediaQW,
                              height: mediaQH*0.025,
                              alignment: Alignment.center,
                              child: Container(
                                  width: mediaQW*0.8,
                                  height: mediaQH*0.025,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(responseJsonData!["responses"][0]["labelAnnotations"][index]["description"]),
                                      Stack(
                                        children: [
                                          Container(
                                            height: 10,
                                            width: 100,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                          ),
                                          Container(
                                            height: 10,
                                            width: (responseJsonData!["responses"][0]["labelAnnotations"][index]["score"] * 100),
                                            decoration: BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                          ),

                                        ],
                                      ),
                                    ],

                                  )),
                            ),
                          );
                        },
                      ),
                    ) :

                    responseJsonText!["responses"][0].toString().length > 2  ?

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          physics: BouncingScrollPhysics(),
                          child: SelectableText(responseJsonText!["responses"][0]["textAnnotations"][0]["description"],style: TextStyle(
                            fontSize: 16,
                          ),)),
                    ) :

                    Text("No Text Found"):

                    Center(child: CircularProgressIndicator()),
                  ],
                ) :

                Center(child: Text("Select an Image")) :

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SelectableText(result ?? "Something went wrong"),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 5,
            child: Container(
              height: mediaQW*0.15,
              width: mediaQW,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  //Text Detection
                  GestureDetector(
                    onTap: (){
                      _pickImage(1, false);
                    },
                    child: Container(
                      height: mediaQW*0.15,
                      width: mediaQW*0.15,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.camera,color: responseJsonText != null ? Colors.white : Colors.black,),
                    ),
                  ),

                  //Text Detection
                  GestureDetector(
                    onTap: (){
                      _pickImage(0, false);
                    },
                    child: Container(
                      height: mediaQW*0.15,
                      width: mediaQW*0.15,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.text_fields,color: responseJsonText != null ? Colors.white : Colors.black,),
                    ),
                  ),

                  //Gallery
                  GestureDetector(
                    onTap: (){
                      _pickImage(0, true);
                    },
                    child: Container(
                      height: mediaQW*0.15,
                      width: mediaQW*0.15,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.image,color: responseJsonData != null ? Colors.white : Colors.black,),
                    ),
                  ),

                  //Camera
                  GestureDetector(
                    onTap: (){
                      _pickImage(1,true);
                    },
                    child: Container(
                      height: mediaQW*0.15,
                      width: mediaQW*0.15,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.camera_alt,color: responseJsonData != null ? Colors.white : Colors.black,),
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