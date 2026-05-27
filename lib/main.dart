import 'package:flutter/material.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyAcLLTFOtuw0VuTEt4oC2nUyWQxQloj9jM",
  authDomain: "fitfoco-7dbbe.firebaseapp.com",
  projectId: "fitfoco-7dbbe",
  storageBucket: "fitfoco-7dbbe.firebasestorage.app",
  messagingSenderId: "506837610404",
  appId: "1:506837610404:web:3671f2820079fd50cc5b31",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialização dinâmica: tenta carregar o nativo primeiro, usa a Web como plano B
  try {
    await Firebase.initializeApp();
  } catch (e) {
    await Firebase.initializeApp(options: firebaseConfig);
  }

  // Cache offline: na próxima abertura carrega do disco instantaneamente
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const App());
}