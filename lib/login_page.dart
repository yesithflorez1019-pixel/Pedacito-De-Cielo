import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'util/app_colors.dart';



class LoginPage extends StatelessWidget {
  const LoginPage({super.key});


  Future<void> signInWithGoogle() async {
    try {

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {

        return;
      }


      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );


      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {

      print("Error en el inicio de sesión con Google: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kColorBackground1, kColorBackground2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bakery_dining_outlined, color: kColorPrimary, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Bienvenido a Pedacito de Cielo',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kColorTextDark),
                ),
                const SizedBox(height: 16),
                Text(
                  'Inicia sesión para guardar y sincronizar tus datos de forma segura.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: kColorTextDark.withOpacity(0.7)),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: signInWithGoogle,

                  icon: Image.asset('assets/google_logo.png', height: 24.0), 
                  label: const Text('Iniciar sesión con Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kColorTextDark,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}