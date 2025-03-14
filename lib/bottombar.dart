import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {

  const BottomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(flex: 1, child: _navButton(route: 'contacts', context: context)),
        Expanded(flex: 2, child: _navButton(route: 'map', context: context)),
        Expanded(flex: 1, child: _navButton(route: 'profile', context: context))

      ],
    );
  }
}

class _navButton extends StatelessWidget {
  final String route;
  final BuildContext context;

  const _navButton({
    super.key,
    required this.route,
    required this.context
  });

  void _navigate() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/$route',
        (route) => false,
    );
  }

  Icon decideIcon() {
    if(route == 'contacts'){
      return Icon (
        Icons.contacts,
        color: Colors.blueGrey,
      );
    }
    else if (route == 'map'){
      return Icon(
        Icons.map,
        color: Colors.blueGrey,
      );
    }
    else {
      return Icon (
        Icons.person,
        color: Colors.blueGrey,
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    String? currentRoute = ModalRoute.of(context)?.settings.name;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        border: Border.all(color: Colors.blueGrey, width: 2),
        color: ('/$route' == currentRoute) ? Color(0xFFD3D3D3) : Colors.transparent
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () => _navigate(),
        child: decideIcon(),
      )
    );
  }

}