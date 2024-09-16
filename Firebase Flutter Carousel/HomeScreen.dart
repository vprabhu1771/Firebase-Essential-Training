import 'package:carousel_images/carousel_images.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final List<String> listImages = [
    'https://firebasestorage.googleapis.com/v0/b/kkchating-e9f00.appspot.com/o/Sprite-Juice-New-HCCB.jpg?alt=media&token=719deb79-3bb7-4b4b-b0ab-04042c4197b7',
    'https://firebasestorage.googleapis.com/v0/b/kkchating-e9f00.appspot.com/o/Brown-eggs.webp?alt=media&token=cefad7d4-a38f-4c59-908f-4c1377b75ad0',
    'https://firebasestorage.googleapis.com/v0/b/kkchating-e9f00.appspot.com/o/__opt__aboutcom__coeus__resources__content_migration__serious_eats__seriouseats.com__2015__07__20210324-SouthernFriedChicken-Andrew-Janjigian-21-cea1fe39234844638018b15259cabdc2.jpg?alt=media&token=f6f2602d-788b-48ed-813a-4079730d6904',
    'https://firebasestorage.googleapis.com/v0/b/kkchating-e9f00.appspot.com/o/pinkyy.jpg?alt=media&token=14cb275c-8751-492c-9601-9143677bfef1'
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: <Widget>[
          SizedBox(height: 100),
          CarouselImages(
            scaleFactor: 0.7,
            listImages: listImages,
            height: 300.0,
            borderRadius: 30.0,
            cachedNetworkImage: true,
            verticalAlignment: Alignment.bottomCenter,
            onTap: (index) {
              print('Tapped on page $index');
            },
          )
        ],
      ),
    );
  }
}
