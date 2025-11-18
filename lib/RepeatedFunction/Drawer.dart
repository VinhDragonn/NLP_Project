import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:r08fullmovieapp/SectionHomeUi/FavoriateList.dart';
import 'package:r08fullmovieapp/SectionHomeUi/HistoryList.dart';
import 'package:r08fullmovieapp/SectionHomeUi/TagList.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'repttext.dart';
import 'package:r08fullmovieapp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:r08fullmovieapp/services/favorite_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:r08fullmovieapp/DetailScreen/predict_screen.dart';

class drawerfunc extends StatefulWidget {
  const drawerfunc({
    super.key,
  });

  @override
  State<drawerfunc> createState() => _drawerfuncState();
}

class _drawerfuncState extends State<drawerfunc> {
  File? _image;
  String? _userEmail;
  String? _userName;
  String? _userPhotoUrl;

  Future<void> SelectImage() async {
    final pickedfile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedfile != null) {
      CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: pickedfile.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      );
      SharedPreferences sp = await SharedPreferences.getInstance();
      sp.setString('imagepath', cropped!.path);
      _image = cropped as File?;
    } else {
      print('No image selected.');
    }
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((sp) {
      setState(() {
        _image = File(sp.getString('imagepath')!);
      });
    });
    // Lấy thông tin user
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _userEmail = user?.email;
      _userPhotoUrl = user?.photoURL;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color.fromRGBO(18, 18, 18, 0.9),
        child: ListView(
          children: [
            DrawerHeader(
              child: Container(
                height: 100,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await SelectImage();
                        //toast message
                        Fluttertoast.showToast(
                            msg: "Image Changed",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.grey,
                            textColor: Colors.white,
                            fontSize: 16.0);
                      },
                      child: _userPhotoUrl != null
                          ? CircleAvatar(
                              radius: 45,
                              backgroundImage: NetworkImage(_userPhotoUrl!),
                            )
                          : _image == null
                              ? CircleAvatar(
                                  radius: 45,
                                  backgroundImage: AssetImage('assets/user.png'),
                                )
                              : CircleAvatar(
                                  radius: 45,
                                  backgroundImage: FileImage(_image!),
                                ),
                    ),
                    SizedBox(height: 2),

                    Text(
                      _userEmail ?? 'Welcome',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            listtilefunc('Home', Icons.home, ontap: () {
              //close drawer
              Navigator.pop(context);
            }),
            listtilefunc('Favorite', Icons.favorite, ontap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => FirestoreFavoriteList()));
            }),
            listtilefunc('History', Icons.history, ontap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => HistoryList()));
            }),
            listtilefunc('Tag', Icons.label, ontap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => TagList()));
            }),
            listtilefunc('Predict Success', Icons.insights, ontap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PredictScreen()),
              );
            }),
            listtilefunc('Quit', Icons.exit_to_app_rounded, ontap: () async {
              await AuthService().signOut();
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Đóng Drawer nếu có thể
              }
              // Chuyển về màn hình đăng nhập (nếu cần, có thể dùng pushReplacement)
            }),
          ],
        ),
      ),
    );
  }
}

Widget listtilefunc(String title, IconData icon, {Function? ontap}) {
  return GestureDetector(
    onTap: ontap as void Function()?,
    child: ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
    ),
  );
}

class FirestoreFavoriteList extends StatelessWidget {
  final FavoriteService _favoriteService = FavoriteService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Movies'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Color.fromRGBO(18, 18, 18, 1),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _favoriteService.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No favorite movies', style: TextStyle(color: Colors.white70)));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return ListTile(
                leading: data['tmdbposter'] != null && data['tmdbposter'] != ''
                    ? Image.network('https://image.tmdb.org/t/p/w92${data['tmdbposter']}', width: 40)
                    : Icon(Icons.movie, color: Colors.amber),
                title: Text(data['tmdbname'] ?? '', style: TextStyle(color: Colors.white)),
                subtitle: Text('Rating: ${data['tmdbrating']}', style: TextStyle(color: Colors.white70)),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await _favoriteService.removeFavorite(docs[index].id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
