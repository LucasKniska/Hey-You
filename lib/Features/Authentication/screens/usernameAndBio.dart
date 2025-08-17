

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../Data/repositories/user/user_repository.dart';

class UserNameAndBio extends StatefulWidget {
  const UserNameAndBio({super.key});

  @override
  State<UserNameAndBio> createState() => _UserNameAndBioState();
}

class _UserNameAndBioState extends State<UserNameAndBio> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              /// Header
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tell Us About Yourself',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This information will help us personalize your profile and find you relevant connections. This information will be shared with other users.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  /// First Name
                  Expanded(
                    child: TextFormField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: Icon(Iconsax.user),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your first name' : null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  /// Last Name
                  Expanded(
                    child: TextFormField(
                      controller: lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        prefixIcon: Icon(Iconsax.user),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your last name' : null,
                    ),
                  ),
                ]
              ),

              const SizedBox(height: 16),


              /// Bio
              TextFormField(
                controller: bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Biography',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Iconsax.note),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter your bio' : null,
              ),
              const SizedBox(height: 24),

              /// Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {

                      UserRepository.instance.updateUserField('FirstName', firstNameController.text);
                      UserRepository.instance.updateUserField('LastName', lastNameController.text);
                      UserRepository.instance.updateUserField('Biography', bioController.text);

                      print('Get back from username and bio');
                      Get.back();
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
