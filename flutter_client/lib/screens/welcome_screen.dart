import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Energy Audit'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to the Home Energy Audit App',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24.0),
              Text(
                'This app helps you perform a step-by-step energy evaluation of your home.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 36.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/home_info');
                },
                child: Text('Start Audit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
