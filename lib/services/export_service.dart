import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/tontine.dart';
import '../models/membre.dart';
import '../models/cotisation.dart';

class ExportService {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final NumberFormat _formatteur = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  static Future<void> exportRapportTontine({
    required Tontine tontine,
    required List<Membre> membres,
    required List<Cotisation> cotisations,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // En-tête
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'RAPPORT DE TONTINE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  _dateTimeFormat.format(DateTime.now()),
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          // Informations de la tontine
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      tontine.nom,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: tontine.statut == 'active' ? PdfColors.green100 : PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        tontine.statut == 'active' ? 'Active' : 'Terminée',
                        style: pw.TextStyle(
                          color: tontine.statut == 'active' ? PdfColors.green : PdfColors.grey700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Montant', _formatteur.format(tontine.montant)),
                          _buildInfoRow('Fréquence', tontine.frequenceLibelle),
                          _buildInfoRow('Membres', '${tontine.membres}'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Début', _dateFormat.format(tontine.dateDebut)),
                          _buildInfoRow('Objectif', _formatteur.format(tontine.montant * tontine.membres)),
                          _buildInfoRow('Collecté', _formatteur.format(tontine.montantTotal)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Liste des membres
          pw.Text(
            'Liste des membres',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headers: ['N°', 'Nom', 'Prénom', 'Téléphone'],
            data: membres.asMap().entries.map((e) {
              return [
                (e.key + 1).toString(),
                e.value.nom,
                e.value.prenom,
                e.value.telephone,
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),

          // Liste des cotisations
          pw.Text(
            'Historique des cotisations',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headers: ['Membre', 'Montant', 'Date', 'Mode'],
            data: cotisations.map((c) {
              return [
                c.membreNom,
                _formatteur.format(c.montant),
                _dateFormat.format(c.datePaiement),
                c.modePaiement ?? '-',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text('$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(value),
      ],
    );
  }
}