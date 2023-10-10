import 'package:async_queue/async_queue.dart';
import 'package:flutter/material.dart';

enum JobLabel {
  job1,
  job2,
  job3,
  job4,
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> _jobsList = [];
  final List<String> _clickList = [];
  final aQ = AsyncQueue.autoStart(
      // allowDuplicate: false,
      );
  String _label = '';

  JobLabel? _currentJobLabel;

  @override
  void initState() {
    super.initState();
    aQ.addQueueListener(
      (event) =>
          setState(() => _label = "running ${event.jobLabel} - ${event.type}"),
    );
    aQ.currentJobUpdate(
        (jobLabel) => setState(() => _currentJobLabel = jobLabel as JobLabel?));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_currentJobLabel.toString()),
            Text(_label),
            const Divider(height: 20),
            Wrap(
              // mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Button click: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ..._clickList
                    .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(e)))
                    .toList()
              ],
            ),
            const Divider(height: 20),
            Wrap(
              // mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Job Results: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ..._jobsList
                    .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(e)))
                    .toList()
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() => _clickList.add("button 1"));
                    aQ.addJob(
                      label: JobLabel.job1,
                      (_) => Future.delayed(const Duration(milliseconds: 1000),
                          () => setState(() => _jobsList.add("Job 1"))),
                    );
                  },
                  child: _currentJobLabel == JobLabel.job1
                      ? const CircularProgressIndicator()
                      : const Text("Job 1"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _clickList.add("button 2"));
                    aQ.addJob(
                      label: JobLabel.job2,
                      (_) => Future.delayed(const Duration(milliseconds: 4000),
                          () => setState(() => _jobsList.add("Job 2"))),
                    );
                  },
                  child: _currentJobLabel == JobLabel.job2
                      ? const CircularProgressIndicator()
                      : const Text("Job 2"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _clickList.add("button 3"));
                    aQ.addJob(
                      label: JobLabel.job3,
                      (_) => Future.delayed(const Duration(milliseconds: 2000),
                          () => setState(() => _jobsList.add("Job 3"))),
                    );
                  },
                  child: _currentJobLabel == JobLabel.job3
                      ? const CircularProgressIndicator()
                      : const Text("Job 3"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _clickList.add("button 4"));
                    aQ.addJob(
                      label: JobLabel.job4,
                      (_) => Future.delayed(const Duration(milliseconds: 1000),
                          () => setState(() => _jobsList.add("Job 4"))),
                    );
                  },
                  child: _currentJobLabel == JobLabel.job4
                      ? const CircularProgressIndicator()
                      : const Text("Job 4"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  aQ.stop();
                  setState(() {
                    _clickList.clear();
                    _jobsList.clear();
                  });
                },
                child: const Text("CLEAR")),
          ],
        ),
      ),
    );
  }
}
