import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:r08fullmovieapp/services/ml_predict_service.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final _formKey = GlobalKey<FormState>();
  final _movieTitle = TextEditingController(text: '');
  final _directors = TextEditingController(text: '');
  final _genres = TextEditingController(text: '');
  final _productionCompany = TextEditingController(text: '');
  final _runtime = TextEditingController(text: '120');
  final _releaseYear = TextEditingController(text: '2015');
  final _audienceRating = TextEditingController(text: '60');
  final _tomatometerCount = TextEditingController(text: '50');
  final _audienceCount = TextEditingController(text: '10000');

  bool _loading = false;
  String? _resultLabel;

  @override
  void dispose() {
    _movieTitle.dispose();
    _directors.dispose();
    _genres.dispose();
    _productionCompany.dispose();
    _runtime.dispose();
    _releaseYear.dispose();
    _audienceRating.dispose();
    _tomatometerCount.dispose();
    _audienceCount.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.amber),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: const Color.fromRGBO(30, 30, 30, 1),
      );

  Widget _gap() => const SizedBox(height: 12);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _resultLabel = null;
    });

    try {
      final svc = MlPredictService();
      final res = await svc.predict(
        movieTitle: _movieTitle.text.isEmpty ? null : _movieTitle.text,
        directors: _directors.text.isEmpty ? 'Unknown' : _directors.text,
        genres: _genres.text.isEmpty ? 'Unknown' : _genres.text,
        productionCompany: _productionCompany.text.isEmpty ? 'Unknown' : _productionCompany.text,
        runtime: double.parse(_runtime.text),
        releaseYear: double.parse(_releaseYear.text),
        audienceRating: double.parse(_audienceRating.text),
        tomatometerCount: double.parse(_tomatometerCount.text),
        audienceCount: double.parse(_audienceCount.text),
      );
      setState(() {
        _resultLabel = res['label']?.toString();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Predict error: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String? _reqStr(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;
  String? _reqNum(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return double.tryParse(v) == null ? 'Must be number' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Predict Movie Success'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _movieTitle,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Movie title (optional)'),
                ),
                _gap(),
                TextFormField(
                  controller: _directors,
                  validator: _reqStr,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Directors'),
                ),
                _gap(),
                TextFormField(
                  controller: _genres,
                  validator: _reqStr,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Genres (e.g., Action|Drama)'),
                ),
                _gap(),
                TextFormField(
                  controller: _productionCompany,
                  validator: _reqStr,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Production company'),
                ),
                _gap(),
                TextFormField(
                  controller: _runtime,
                  validator: _reqNum,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Runtime (minutes)'),
                ),
                _gap(),
                TextFormField(
                  controller: _releaseYear,
                  validator: _reqNum,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Release year'),
                ),
                _gap(),
                TextFormField(
                  controller: _audienceRating,
                  validator: _reqNum,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Audience rating (0-100)'),
                ),
                _gap(),
                TextFormField(
                  controller: _tomatometerCount,
                  validator: _reqNum,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Tomatometer count'),
                ),
                _gap(),
                TextFormField(
                  controller: _audienceCount,
                  validator: _reqNum,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Audience count'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Predict'),
                ),
                if (_resultLabel != null) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _resultLabel == 'Success' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _resultLabel == 'Success' ? Colors.green : Colors.red),
                      ),
                      child: Text(
                        'Prediction: $_resultLabel',
                        style: TextStyle(
                          color: _resultLabel == 'Success' ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
