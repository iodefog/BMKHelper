//
//  BMKSearchHelper.h
//  iWeidao
//
//  Created by LiHongli on 14-7-26.
//  Copyright (c) 2014年 Weidao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMapKit.h"

typedef void(^BMKSearchHelperBlock)(id resopnse , BOOL success);

@interface BMKSearchHelper : NSObject<BMKPoiSearchDelegate,BMKSuggestionSearchDelegate, BMKGeoCodeSearchDelegate>

@property (nonatomic, strong) NSString                  *cityName;
@property (nonatomic, strong) NSString                  *searchString;
@property (nonatomic, assign) BOOL                      needCitySearch;
@property (nonatomic, strong) BMKSuggestionSearch       *search;
@property (nonatomic, strong) BMKPoiSearch              *poiSearch;
@property (nonatomic, strong) BMKSuggestionSearchOption *suggestionSearch;
@property (nonatomic, strong) BMKCitySearchOption       *citySearchOption;
@property (nonatomic, strong) BMKGeoCodeSearch          *geoCodeSearch;
@property (nonatomic, strong) BMKSearchHelperBlock      helperBlock;
@property (nonatomic, strong) YCAddressModel            *geoCodeModel;


+ (instancetype)shareInstance;

/******
 * 百度搜索， 推荐搜索结果返回推荐关键词，拿到关键词进行更精准搜索
 * param key 搜索词
 * param cityName 搜索城市，不要为nil
 * param needCitySearch 是否需要城市搜索 。NO 单纯关键词搜索，不含城市，YES，关键词搜索
 * param searchBlock 搜索结果回调，返回结果自动调用 - (void)citySearchAddressKey:(NSString *)key cityName:(NSString *)cityName searchBlock:(BMKSearchHelperBlock)searchBlock;
 */
- (void)searchAddressKey:(NSString *)key cityName:(NSString *)cityName needCitySearch:(BOOL)needSearch searchBlock:(BMKSearchHelperBlock)searchBlock;


/******
 * 百度搜索， 关键词搜索结果返回相关结果，拿到结果后进行生成只含 “name”， “address”，“latitude”，“longitude”
 * param key 搜索词
 * param cityName 搜索城市，不要为nil
 * param searchBlock 搜索结果回调 回调结果为数组;
 */
- (void)citySearchAddressKey:(NSString *)key cityName:(NSString *)cityName searchBlock:(BMKSearchHelperBlock)searchBlock;

- (void)bmkGeoCodeSearchModel:(YCAddressModel *)addressModel searchBlock:(BMKSearchHelperBlock)searchBlock;


@end
