// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAuthorDto _$PostAuthorDtoFromJson(Map<String, dynamic> json) =>
    PostAuthorDto(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );

Map<String, dynamic> _$PostAuthorDtoToJson(PostAuthorDto instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'photoUrl': instance.photoUrl,
    };

CommunityPostDto _$CommunityPostDtoFromJson(Map<String, dynamic> json) =>
    CommunityPostDto(
      id: json['id'] as String,
      author: PostAuthorDto.fromJson(json['author'] as Map<String, dynamic>),
      reactionCount: (json['reactionCount'] as num).toInt(),
      commentCount: (json['commentCount'] as num).toInt(),
      hasReacted: json['hasReacted'] as bool,
      createdAt: json['createdAt'] as String,
      content: json['content'] as String?,
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CommunityPostDtoToJson(CommunityPostDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author': instance.author,
      'content': instance.content,
      'photos': instance.photos,
      'reactionCount': instance.reactionCount,
      'commentCount': instance.commentCount,
      'hasReacted': instance.hasReacted,
      'createdAt': instance.createdAt,
    };

CommunityCommentDto _$CommunityCommentDtoFromJson(Map<String, dynamic> json) =>
    CommunityCommentDto(
      id: json['id'] as String,
      postId: json['postId'] as String,
      author: PostAuthorDto.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      createdAt: json['createdAt'] as String,
      parentCommentId: json['parentCommentId'] as String?,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CommunityCommentDtoToJson(
  CommunityCommentDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'postId': instance.postId,
  'author': instance.author,
  'content': instance.content,
  'parentCommentId': instance.parentCommentId,
  'replyCount': instance.replyCount,
  'createdAt': instance.createdAt,
};

FeedResponseDto _$FeedResponseDtoFromJson(Map<String, dynamic> json) =>
    FeedResponseDto(
      posts: (json['posts'] as List<dynamic>)
          .map((e) => CommunityPostDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['hasMore'] as bool,
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$FeedResponseDtoToJson(FeedResponseDto instance) =>
    <String, dynamic>{
      'posts': instance.posts,
      'nextCursor': instance.nextCursor,
      'hasMore': instance.hasMore,
    };

CommentsResponseDto _$CommentsResponseDtoFromJson(Map<String, dynamic> json) =>
    CommentsResponseDto(
      comments: (json['comments'] as List<dynamic>)
          .map((e) => CommunityCommentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['hasMore'] as bool,
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$CommentsResponseDtoToJson(
  CommentsResponseDto instance,
) => <String, dynamic>{
  'comments': instance.comments,
  'nextCursor': instance.nextCursor,
  'hasMore': instance.hasMore,
};
