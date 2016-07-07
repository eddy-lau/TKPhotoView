//
//  TKPhotoViewController-Bridging-Header.h
//
//  Created by Eddie Hiu-Fung Lau on 3/11/2015.
//

#ifndef TKPhotoViewController_Bridging_Header_h
#define TKPhotoViewController_Bridging_Header_h

#import "AFNetworking/AFNetworking.h"

@interface UIImageView (_AFNetworking)
@property (readwrite, nonatomic, strong, setter = af_setImageRequestOperation:) AFHTTPRequestOperation *af_imageRequestOperation;
@end

#endif /* TKPhotoViewController_Bridging_Header_h */
