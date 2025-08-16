

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Tell Us About Yourself',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your name and a short bio',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                /// First Name
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Iconsax.user),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your first name' : null,
                ),
                const SizedBox(height: 16),

                /// Last Name
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Iconsax.user_edit),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your last name' : null,
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
      ),
    );
  }
}
