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
  final List<String> _selectedCategories = [];
  bool _showOnlyImportant = false;

  // 태그 카테고리 정의
  final List<String> _categories = ['환자 정보', '검사 정보', '이미지 정보', '장비 정보', '기타'];

  // 중요 태그 목록
  final List<String> _importantTags = [
    '00100010', // PatientName
    '00100020', // PatientID
    '00080020', // StudyDate
    '00080060', // Modality
    '00081030', // StudyDescription
    '0008103E', // SeriesDescription
    '00280010', // Rows
    '00280011', // Columns
    '00280030', // PixelSpacing
    '00200037', // ImageOrientationPatient
    '00200032', // ImagePositionPatient
    '00281050', // WindowCenter
    '00281051', // WindowWidth
  ];

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

  // 태그 매핑 - 태그를 카테고리별로 분류
  String _mapTagToCategory(String tagId, DicomTag tag) {
    final group = tag.group;

    if (group == '0010') return '환자 정보';
    if (group == '0008') return '검사 정보';
    if (group == '0028') return '이미지 정보';
    if (group == '0018') return '장비 정보';
    return '기타';
  }

  // 태그 검색 필터링
  void _filterTags() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredTags =
          widget.dicomFile.tags.entries.where((entry) {
            final tag = entry.value;
            final category = _mapTagToCategory(entry.key, tag);

            // 카테고리 필터링
            if (_selectedCategories.isNotEmpty &&
                !_selectedCategories.contains(category)) {
              return false;
            }

            // 중요 태그 필터링
            if (_showOnlyImportant && !_importantTags.contains(entry.key)) {
              return false;
            }

            // 텍스트 검색
            if (query.isEmpty) {
              return true;
            }

            return tag.name.toLowerCase().contains(query) ||
                tag.group.toLowerCase().contains(query) ||
                tag.element.toLowerCase().contains(query) ||
                tag.value.toLowerCase().contains(query);
          }).toList();
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

  // 태그 전체 정보 복사
  void _copyTagInfo(DicomTag tag) {
    final info =
        '(${tag.group},${tag.element}) ${tag.name} [${tag.vr}]: ${tag.value}';
    Clipboard.setData(ClipboardData(text: info));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('태그 정보 복사됨'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DICOM 태그'),
        actions: [
          // 중요 태그만 표시 토글
          IconButton(
            icon: Icon(
              _showOnlyImportant ? Icons.star : Icons.star_border,
              color: _showOnlyImportant ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() {
                _showOnlyImportant = !_showOnlyImportant;
                _filterTags();
              });
            },
            tooltip: '중요 태그만 표시',
          ),
          // 필터 메뉴
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: '카테고리 필터',
            onSelected: (category) {
              setState(() {
                if (_selectedCategories.contains(category)) {
                  _selectedCategories.remove(category);
                } else {
                  _selectedCategories.add(category);
                }
                _filterTags();
              });
            },
            itemBuilder: (context) {
              return _categories.map((category) {
                return CheckedPopupMenuItem<String>(
                  value: category,
                  checked: _selectedCategories.contains(category),
                  child: Text(category),
                );
              }).toList();
            },
          ),
        ],
      ),
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

          // 환자 정보 요약 카드
          _buildPatientInfoCard(),

          // 활성화된 필터 표시
          if (_selectedCategories.isNotEmpty || _showOnlyImportant)
            _buildActiveFilters(),

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
                        final category = _mapTagToCategory(entry.key, tag);
                        final isImportant = _importantTags.contains(entry.key);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  '(${tag.group},${tag.element})',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isImportant)
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                Expanded(
                                  child: Text(
                                    tag.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${tag.vr}: ${tag.value}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                Text(
                                  category,
                                  style: TextStyle(
                                    color: _getCategoryColor(category),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.content_copy,
                                    size: 20,
                                  ),
                                  onPressed: () => _copyTagValue(tag),
                                  tooltip: '값 복사',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.info_outline,
                                    size: 20,
                                  ),
                                  onPressed:
                                      () => _showTagDetails(
                                        tag,
                                        category,
                                        isImportant,
                                      ),
                                  tooltip: '상세 정보',
                                ),
                              ],
                            ),
                            onTap:
                                () =>
                                    _showTagDetails(tag, category, isImportant),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // 환자 정보 요약 카드
  Widget _buildPatientInfoCard() {
    return Card(
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
                TableRow(
                  children: [
                    const Text('검사 설명:'),
                    Text(widget.dicomFile.studyDescription),
                  ],
                ),
                TableRow(
                  children: [
                    const Text('시리즈 설명:'),
                    Text(widget.dicomFile.seriesDescription),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 활성화된 필터 표시 위젯
  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      width: double.infinity,
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          if (_showOnlyImportant)
            Chip(
              label: const Text('중요 태그'),
              avatar: const Icon(Icons.star, size: 16),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                setState(() {
                  _showOnlyImportant = false;
                  _filterTags();
                });
              },
            ),
          ..._selectedCategories.map(
            (category) => Chip(
              label: Text(category),
              avatar: Icon(_getCategoryIcon(category), size: 16),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                setState(() {
                  _selectedCategories.remove(category);
                  _filterTags();
                });
              },
              backgroundColor: _getCategoryColor(category).withOpacity(0.2),
            ),
          ),
          if (_showOnlyImportant || _selectedCategories.isNotEmpty)
            ActionChip(
              label: const Text('모두 지우기'),
              avatar: const Icon(Icons.clear_all, size: 16),
              onPressed: () {
                setState(() {
                  _showOnlyImportant = false;
                  _selectedCategories.clear();
                  _filterTags();
                });
              },
            ),
        ],
      ),
    );
  }

  // 카테고리별 색상 지정
  Color _getCategoryColor(String category) {
    switch (category) {
      case '환자 정보':
        return Colors.blue;
      case '검사 정보':
        return Colors.green;
      case '이미지 정보':
        return Colors.purple;
      case '장비 정보':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // 카테고리별 아이콘 지정
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '환자 정보':
        return Icons.person;
      case '검사 정보':
        return Icons.assignment;
      case '이미지 정보':
        return Icons.image;
      case '장비 정보':
        return Icons.settings;
      default:
        return Icons.dehaze;
    }
  }

  // 태그 상세 정보 대화상자
  void _showTagDetails(DicomTag tag, String category, bool isImportant) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Text('태그 상세 정보'),
                const Spacer(),
                if (isImportant) const Icon(Icons.star, color: Colors.amber),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('그룹', tag.group),
                  _buildDetailRow('요소', tag.element),
                  _buildDetailRow('이름', tag.name),
                  _buildDetailRow('VR', tag.vr),
                  _buildDetailRow(
                    '카테고리',
                    category,
                    _getCategoryColor(category),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('값:'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      tag.value,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _copyTagInfo(tag);
                  Navigator.of(context).pop();
                },
                child: const Text('전체 복사'),
              ),
              TextButton(
                onPressed: () {
                  _copyTagValue(tag);
                  Navigator.of(context).pop();
                },
                child: const Text('값만 복사'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ],
          ),
    );
  }

  // 상세 정보 행 위젯
  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(color: valueColor))),
        ],
      ),
    );
  }
}
