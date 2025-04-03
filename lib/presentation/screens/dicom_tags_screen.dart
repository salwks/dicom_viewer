import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/dicom_file.dart';

class DicomTagsScreen extends StatefulWidget {
  final DicomFile dicomFile;

  const DicomTagsScreen({super.key, required this.dicomFile});

  @override
  State<DicomTagsScreen> createState() => _DicomTagsScreenState();
}

class _DicomTagsScreenState extends State<DicomTagsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MapEntry<String, DicomTag>> _filteredTags = [];

  @override
  void initState() {
    super.initState();
    _filteredTags = widget.dicomFile.tags.entries.toList();
    _searchController.addListener(_filterTags);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 태그 검색 필터링
  void _filterTags() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredTags = widget.dicomFile.tags.entries.toList();
      } else {
        _filteredTags =
            widget.dicomFile.tags.entries.where((entry) {
              final tag = entry.value;
              return tag.name.toLowerCase().contains(query) ||
                  tag.group.toLowerCase().contains(query) ||
                  tag.element.toLowerCase().contains(query) ||
                  tag.value.toLowerCase().contains(query);
            }).toList();
      }
    });
  }

  // 태그 값 복사
  void _copyTagValue(DicomTag tag) {
    Clipboard.setData(ClipboardData(text: tag.value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('복사됨: ${tag.value}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DICOM 태그')),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '태그 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
              ),
            ),
          ),

          // 환자 정보 요약
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('환자 정보', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        children: [
                          const Text('환자 이름:'),
                          Text(widget.dicomFile.patientName),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Text('환자 ID:'),
                          Text(widget.dicomFile.patientId),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Text('검사 날짜:'),
                          Text(widget.dicomFile.studyDate),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Text('모달리티:'),
                          Text(widget.dicomFile.modality),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 태그 목록
          Expanded(
            child:
                _filteredTags.isEmpty
                    ? const Center(child: Text('검색 결과가 없습니다.'))
                    : ListView.builder(
                      itemCount: _filteredTags.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredTags[index];
                        final tag = entry.value;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            title: Text(
                              '(${tag.group},${tag.element}) ${tag.name}',
                            ),
                            subtitle: Text('${tag.vr}: ${tag.value}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.content_copy),
                              onPressed: () => _copyTagValue(tag),
                              tooltip: '값 복사',
                            ),
                            onTap: () => _copyTagValue(tag),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
