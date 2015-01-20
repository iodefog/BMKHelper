//  BMKSearchHelper.m
//  iWeidao
//
//  Created by LiHongli on 14-7-26.
//  Copyright (c) 2014年 Weidao. All rights reserved.
//

#import "BMKSearchHelper.h"
//#import "YCTools.h"
//#import "CLLocation+YCLocation.h"

@implementation BMKSearchHelper

+ (instancetype)shareInstance{
    // 一次性执行：
    static  BMKSearchHelper *helper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // code to be executed once
        helper = [[BMKSearchHelper alloc] init];
        [helper instanceBMKSearch];
    });
    return helper;
}

/***** 初始化
 *
 */
- (void)instanceBMKSearch{
    if (!_search) {
        _search = [[BMKSuggestionSearch alloc] init];
        _search.delegate = self;
    }
    
    if (!_geoCodeSearch) {
        _geoCodeSearch = [[BMKGeoCodeSearch alloc] init];
        _geoCodeSearch.delegate = self;
    }
    
    if (!_poiSearch) {
        _poiSearch = [[BMKPoiSearch alloc] init];
        _poiSearch.delegate = self;
    }
    
    if (!_suggestionSearch) {
        _suggestionSearch = [[BMKSuggestionSearchOption alloc] init];
    }
    
    if (!_citySearchOption) {
        _citySearchOption = [[BMKCitySearchOption alloc]init];
    }
}


/******
 * 百度搜索， 推荐搜索结果返回推荐关键词，拿到关键词进行更精准搜索
 * param key 搜索词
 * param cityName 搜索城市，不要为nil
 * param needCitySearch 是否需要城市搜索 。NO 单纯关键词搜索，不含城市，YES，关键词搜索
 * param searchBlock 搜索结果回调，返回结果自动调用 - (void)citySearchAddressKey:(NSString *)key cityName:(NSString *)cityName searchBlock:(BMKSearchHelperBlock)searchBlock;
 */
- (void)searchAddressKey:(NSString *)key cityName:(NSString *)cityName needCitySearch:(BOOL)needSearch searchBlock:(BMKSearchHelperBlock)searchBlock{
    // 如果_cityName 为空，就返回，避免是用 rangeOfString 函数时，崩溃
    if (!cityName) {
        searchBlock(nil, YES);
        return;
    }
    _needCitySearch = needSearch;
    if (needSearch) {
        _cityName = cityName;
        _suggestionSearch.cityname = cityName;
    }else {
        _cityName = cityName;
        _suggestionSearch.cityname = nil;
    }
    self.searchString = key;
    _suggestionSearch.keyword = key;
    _helperBlock = searchBlock;
    [_search suggestionSearch:_suggestionSearch];
}

/******
 * 百度搜索， 关键词搜索结果返回相关结果，拿到结果后进行生成只含 “name”， “address”，“latitude”，“longitude”
 * param key 搜索词
 * param cityName 搜索城市，不要为nil
 * param searchBlock 搜索结果回调 回调结果为数组;
 */
- (void)citySearchAddressKey:(NSString *)key cityName:(NSString *)cityName searchBlock:(BMKSearchHelperBlock)searchBlock{
    // 如果_cityName 为空，就返回，避免是用 rangeOfString 函数时，崩溃
    if (!cityName) {
        searchBlock(nil, YES);
        return;
    }
    _cityName = cityName;
    _citySearchOption.pageIndex = 0;
    _citySearchOption.pageCapacity = 20;
    _citySearchOption.city= _cityName;
    _citySearchOption.keyword = key;
    if (searchBlock) {
        _helperBlock = searchBlock;
    }
    BOOL flag = [_poiSearch poiSearchInCity:_citySearchOption];
    if(flag){
                      NSLog(@"城市内检索发送成功");
    } else {
               NSLog(@"城市内检索发送失败");
        _helperBlock(nil, NO);
    }
}

#pragma mark -BMKSearchDelegate
/****** 返回第一步，  获取在线推荐搜索  注释未启用
 *
 */
- (void)onGetSuggestionResult:(BMKSuggestionSearch*)searcher result:(BMKSuggestionResult*)result errorCode:(BMKSearchErrorCode)error{
    NSArray *keyList = result.keyList;
    NSArray *cityList = result.cityList;
    NSArray *districtList = result.districtList;

    
//    if (!_needCitySearch) {
//        _helperBlock([self dictionaryWithKeyArray:keyList cityArray:cityList], YES);
//        return;
//    }
    
    int index = 0;
    
    // 1. 有推荐城市时，使用推荐城市，没有推荐城市时，直接搜索
    if (cityList.count > 0) {
        NSInteger legalCount = 0; // 统计推荐城市里合法的城市
        
        for (NSString *city in cityList) {
            if (city.length != 0) {
                legalCount ++;
                if (_needCitySearch) {
                    NSRange range = [city rangeOfString:_cityName];
                    if (range.length != 0) {
                        NSString *key = [keyList objectAtIndex:index];
                        [self citySearchAddressKey:key cityName:_cityName searchBlock:nil];
                        break;
                    }
                }else {
                    // 2. 使用推荐城市搜索
                    NSString *district = (index < districtList.count) ? districtList[index] : nil;
                    BOOL cityCheck = [city isKindOfClass:[NSString class]] &&  (city.length > 0);
                    BOOL districtCheck = [district isKindOfClass:[NSString class]] &&  (district.length > 0);
                    
                    if(cityCheck && districtCheck){
                        [self citySearchAddressKey:self.searchString cityName:city searchBlock:nil];
                        break;
                    }
                }
            }
            index ++;
        }
        
        if(legalCount == 0 && !_needCitySearch){ // 3. 当返回的结果里没有合法的城市
            [self citySearchAddressKey:self.searchString cityName:_cityName searchBlock:nil];
        }
    } else {
        [self citySearchAddressKey:self.searchString cityName:_cityName searchBlock:nil];
    }
}


/******  返回第二步， 获取关键词搜索 未使用
 *
 */
- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPoiResult*)poiResult errorCode:(BMKSearchErrorCode)errorCode{

    NSMutableArray *poiAddress = [NSMutableArray array];
    if (poiResult.poiInfoList.count != 0) {
        //        BMKPoiResult *poiResult = [poiResult.poiInfoList objectAtIndex:0];
        if (poiResult.poiInfoList.count != 0) {
            [poiAddress removeAllObjects];
            for (BMKPoiInfo *poiInfo in poiResult.poiInfoList) {
                NSRange range =[poiInfo.city rangeOfString:_cityName];
                if (range.length != 0) {
                    [poiAddress addObject:poiInfo];
                }
            }
        } else {
            [poiAddress removeAllObjects];
        }
    } else {
        [poiAddress removeAllObjects];
    }
    
    _helperBlock(poiAddress, YES);
}


#pragma mark - result parse


@end
