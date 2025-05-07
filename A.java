if (current != null && user != null) ...[
      Text(
        'Current Connection!',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Material(
        color: TColors.accent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            // Handle tap
          },
          borderRadius: BorderRadius.circular(12),
          highlightColor: Colors.white.withOpacity(0.2),
          splashColor: Colors.black.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                current!.userData[user!].userName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Divider(thickness: 1, color: Colors.black12),
    ],