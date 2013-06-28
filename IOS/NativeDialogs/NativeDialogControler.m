//
//  NativeDialogDelegate.m
//  NativeDialogs
//
//  Created by Mateusz Mackowiak on 02.02.2013.
//
//

#import "NativeDialogControler.h"
#import "NativeListDelegate.h"
#import "AlertTextView.h"



@interface ListItem : NSObject
@property( nonatomic, retain ) NSString *text;
@property( nonatomic ) uint32_t selected;
@end


@implementation ListItem

@synthesize text;
@synthesize selected;


+(id)listItemWithText:(NSString*)text{
    return [[[self alloc] initWithText:text] autorelease];
}
- (id)initWithText:(NSString*)_text
{
    self = [super init];
    if (self) {
        self.text = _text;
        self.selected = NO;
    }
    return self;
}
-(NSString *) description {
    return [NSString stringWithFormat:@"ListItem: text: %@ selected: %@",text,(selected ? @"YES":@"NO")];
}
-(void)dealloc{

    [super dealloc];
}

@end





@implementation NativeDialogControler


@synthesize tableItemList;
@synthesize alert;
@synthesize sbAlert;
@synthesize progressView;
@synthesize freContext;

#pragma mark - Alert

- (id)init
{
    self = [super init];
    if (self) {
        cancelable = NO;
    }
    return self;
}


-(void)showAlertWithTitle: (NSString *)title
                  message: (NSString*)message
               closeLabel: (NSString*)closeLabel
              otherLabels: (NSString*)otherLabels
{

    [self dismissWithButtonIndex:0];

    //Create our alert.
    alert = [[UIAlertView alloc] initWithTitle:title
                                        message:message
                                       delegate:self
                              cancelButtonTitle:closeLabel
                              otherButtonTitles:nil];
    
    
    if (otherLabels && ![otherLabels isEqualToString:@""]) {
        //Split our labels into an array
        NSArray *labels = [otherLabels componentsSeparatedByString:@","];
        
        //Add each label to our array.
        for (NSString *label in labels)
        {
            if(label && ![label isEqual:@""])
                [alert addButtonWithTitle:label];
        }
    }
    FREDispatchStatusEventAsync(freContext, (uint8_t*)"nativeDialog_opened", (uint8_t*)"-1");
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}







#pragma mark - Date Picker

- (UIToolbar *)initToolbar:(FREObject *)buttons
{
    UIToolbar *pickerDateToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    pickerDateToolbar.barStyle = UIBarStyleBlackOpaque;
    
    NSMutableArray* barItems = [[NSMutableArray alloc]init];
    
    uint32_t buttons_len;
    FREGetArrayLength(buttons, &buttons_len);
    
    if(buttons_len>0){
        
        uint32_t stingLen;
        const uint8_t *buttonLabel;
        UIBarButtonItem *barButton;
        for (int i = 1; i<buttons_len; i++) {
            FREObject button;
            FREGetArrayElementAt(buttons, i, &button);
            
            FREGetObjectAsUTF8(button, &stingLen, &buttonLabel);
            if(buttonLabel){
                NSString * s= [NSString stringWithUTF8String:(char*)buttonLabel];
                if(s && ![s isEqualToString:@""]){
                    barButton = [[UIBarButtonItem alloc] initWithTitle:s style:UIBarButtonItemStyleBordered target:self action:@selector(actionSheetButtonClicked:)];
                    [barButton setTag:i];
                    [barItems addObject:barButton];
                    [barButton release];
                    barButton = nil;
                }
            }
        }
        
        
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        [barItems addObject:flexSpace];
        [flexSpace release];
        flexSpace = nil;
        
        
        
        FREObject button2;
        FREGetArrayElementAt(buttons, 0, &button2);
        
        FREGetObjectAsUTF8(button2, &stingLen, &buttonLabel);
        if(buttonLabel){
            NSString * s= [NSString stringWithUTF8String:(char*)buttonLabel];
            if(s && ![s isEqualToString:@""]){
                barButton = [[UIBarButtonItem alloc] initWithTitle:s style:UIBarButtonItemStyleBordered target:self action:@selector(actionSheetButtonClicked:)];
                [barButton setTag:0];
                [barItems addObject:barButton];
                [barButton release];
                barButton = nil;
            }
        }
    }else{
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionSheetButtonClicked:)];
        [doneBtn setTag:1];
        
        [barItems addObject:flexSpace];
        [barItems addObject:doneBtn];   
        
        [flexSpace release];
        [doneBtn release];
    }
    
    
    [pickerDateToolbar setItems:barItems animated:NO];
    [barItems release];
    barItems = nil;
    return pickerDateToolbar;
}

-(void)showDatePickerWithTitle:(NSString *)title
                    andMessage:(NSString *)message
                       andDate:(double)date
                      andStyle:(const uint8_t*)style
                    andButtons:(FREObject*)buttons
                  andHasMinMax:(bool)hasMinMax
                        andMin:(double)minDate
                        andMax:(double)maxDate {
    @try {

       
        [self dismissWithButtonIndex:0];
        
        UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0.0, 44.0, 0, 0)];
        [datePicker setDate:[NSDate dateWithTimeIntervalSince1970:date]];
        
        
        if(strcmp((const char *)style, (const char *)"time")==0)
        {
            datePicker.datePickerMode = UIDatePickerModeTime;
        }else if(strcmp((const char *)style, (const char *)"date")==0)
        {
            datePicker.datePickerMode = UIDatePickerModeDate;
        }else if(strcmp((const char *)style, (const char *)"dateAndTime")==0)
        {
            datePicker.datePickerMode = UIDatePickerModeDateAndTime;
        }
        
        if(hasMinMax && datePicker.datePickerMode != UIDatePickerModeTime)
        {
            datePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:minDate];
            datePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:maxDate];
        }
        
        [datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
        
        UIToolbar *pickerDateToolbar = [self initToolbar:buttons];
        
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            UIViewController* popoverContent = [[UIViewController alloc] init];
            
            UIView *popoverView = [[UIView alloc] init];
            popoverView.backgroundColor = [UIColor blackColor];
            
            [popoverView addSubview:datePicker];
            [popoverView addSubview:pickerDateToolbar];
            
            popoverContent.view = popoverView;
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
            popoverController.delegate=self;
            
            UIWindow* wind= [[UIApplication sharedApplication] keyWindow];
                             
            [popoverController setPopoverContentSize:CGSizeMake(320, 264) animated:NO];
            CGFloat viewWidth = wind.frame.size.width;
            CGFloat viewHeight = wind.frame.size.height;
            CGRect rect = CGRectMake(viewWidth/2, viewHeight/2, 1, 1);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [popoverController presentPopoverFromRect:rect inView:wind permittedArrowDirections:0 animated:YES];
            });
            popover = popoverController;
            
            //[popoverController release];
            [popoverView release];
            popoverView = nil;
            [popoverContent release];
            popoverContent = nil;
            
            [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
            
        }else{
            
            UIActionSheet *aac = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
            
            [aac addSubview:pickerDateToolbar];
            [aac addSubview:datePicker];
            
            UIWindow* wind= [[[UIApplication sharedApplication] windows] objectAtIndex:0];
            if(!wind){
                NSLog(@"Window is nil");
                FREDispatchStatusEventAsync(freContext, (const uint8_t*)"error", (const uint8_t*)"Window is nil");
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [aac showInView:wind];
                [aac setBounds:CGRectMake(0,0,320, 464)];
            });
            
            
            actionSheet = aac;
            //[aac release];
        }
        
        [pickerDateToolbar sizeToFit];
        
        
        [datePicker release];
        [pickerDateToolbar release];
        

    }
    @catch (NSException *exception) {
        FREDispatchStatusEventAsync(freContext, (const uint8_t *)"error", (const uint8_t *)[[exception reason] UTF8String]);
    }

}
- (void) didRotate:(NSNotification *)notification{
    if([popover isPopoverVisible]){
        UIWindow* wind= [[UIApplication sharedApplication] keyWindow];
        
        [popover setPopoverContentSize:CGSizeMake(320, 264) animated:NO];
        CGFloat viewWidth = wind.frame.size.width;
        CGFloat viewHeight = wind.frame.size.height;
        CGRect rect = CGRectMake(viewWidth/2, viewHeight/2, 1, 1);
        
        [popover presentPopoverFromRect:rect inView:wind permittedArrowDirections:0 animated:YES];
    }
}

- (BOOL) popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    //FREDispatchStatusEventAsync(freContext, (const uint8_t *)"nativeDialog_pressedOutside", (const uint8_t *)"-1");
    //return NO;
    
    return cancelable;
}

-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice]endGeneratingDeviceOrientationNotifications];
    
    FREDispatchStatusEventAsync(freContext, (const uint8_t *)"nativeDialog_canceled", (const uint8_t *)"-1");
    [popover autorelease];
    popover = nil;
    
}

-(void)dateChanged:(id)sender{
    
    NSDate *date = [sender date];
    NSTimeInterval timeInterval  = [date timeIntervalSince1970];
    
    FREDispatchStatusEventAsync(freContext, (const uint8_t *)"change", (const uint8_t *)[[NSString stringWithFormat:@"%f",timeInterval]UTF8String]);
}
- (void)actionSheetButtonClicked:(UIBarButtonItem*)sender {
    NSInteger index = [sender tag];
    if(cancelable && index == 1)
    {
        FREDispatchStatusEventAsync(freContext, (const uint8_t *)"nativeDialog_canceled", (const uint8_t *)[[NSString stringWithFormat:@"%d",index] UTF8String]);
    }
    else
    {
        FREDispatchStatusEventAsync(freContext, (const uint8_t *)"nativeDialog_closed", (const uint8_t *)[[NSString stringWithFormat:@"%d",index] UTF8String]);
    }
    
    if(popover){
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
        [[UIDevice currentDevice]endGeneratingDeviceOrientationNotifications];
        
        [popover dismissPopoverAnimated:YES];
    }else{
        [actionSheet dismissWithClickedButtonIndex:[sender tag] animated:YES];
        [actionSheet autorelease];
        actionSheet = nil;
    }
   
//    FREDispatchStatusEventAsync(freContext, (const uint8_t *)"nativeDialog_pressedButton", (const uint8_t *)[[NSString stringWithFormat:@"%d",[sender tag]] UTF8String]);
}


-(void)updateDateWithTimestamp:(double)timeStamp{

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    if(actionSheet){
        for (int i = 0; i < [[actionSheet subviews] count]; i++) {
            if ([[actionSheet.subviews objectAtIndex:i] class] == [UIDatePicker class]) {
                UIDatePicker* datepicker = (UIDatePicker*)[actionSheet.subviews objectAtIndex:i];
                [datepicker setDate:date animated:YES];
                break;
            }
        }
        
    }else if(popover){
        UIView* contentView =  [[popover contentViewController] view];
        for (int i = 0; i < [[contentView subviews] count]; i++) {
            if ([[contentView.subviews objectAtIndex:i] class] == [UIDatePicker class]) {
                UIDatePicker* datepicker = (UIDatePicker*)[contentView.subviews objectAtIndex:i];
                [datepicker setDate:[NSDate dateWithTimeIntervalSinceNow:-99999] animated:YES];
                break;
            }
        }
    }
    
    
}



#pragma mark - Progress Dialog
-(void)showProgressPopup: (NSString *)title
                   style: (int32_t)style
                 message: (NSString*)message
                progress: (NSNumber*)progress
            showActivity:(Boolean)showActivity
               cancleble:(Boolean)cancleble{
    
    [self dismissWithButtonIndex:0];
    
    alert = [[UIAlertView alloc] initWithTitle:title
                                             message:message
                                            delegate:self
                                   cancelButtonTitle:nil
                                   otherButtonTitles:nil];
    
    if (style== 0 || showActivity) {
        
        UIActivityIndicatorView *activityWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityWheel.frame = CGRectMake(142.0f-activityWheel.bounds.size.width*.5, 80.0f, activityWheel.bounds.size.width, activityWheel.bounds.size.height);
        [alert addSubview:activityWheel];
        [activityWheel startAnimating];
        [activityWheel release];
        
    } else {
        
        progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(30.0f, 90.0f, 225.0f, 90.0f)];
        [alert addSubview:progressView];
        [progressView setProgressViewStyle: UIProgressViewStyleBar];
        progressView.progress=[progress floatValue];
    }
    [alert setDelegate:self];
    FREDispatchStatusEventAsync(freContext, (uint8_t*)"nativeDialog_opened", (uint8_t*)"-1");
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}


-(void)updateProgress: (CGFloat)perc
{
    [self performSelectorOnMainThread: @selector(updateProgressBar:)
                           withObject: [NSNumber numberWithFloat:perc] waitUntilDone:NO];

}


- (void) updateProgressBar:(NSNumber*)num {
    if(progressView)
        progressView.progress=[num floatValue];
}

#pragma mark - Text Input Dialog



-(void)textFieldDidChange:(id)sender {
    // whatever you wanted to do
    int8_t index = 0;
    if(sender != [alert textFieldAtIndex:0])
        index =1;
    NSString* returnString = [NSString stringWithFormat:@"%i#_#%@",index,((UITextField *)sender).text];
    
    FREDispatchStatusEventAsync(freContext, (uint8_t*)"change", (uint8_t*)[returnString UTF8String]);
    // [returnString release];
}


-(void)textFieldDidPressReturn:(id)sender
{
    int8_t index = 0;
    [sender resignFirstResponder];
    
    if(sender != [alert textFieldAtIndex:0])
        index =1;
    NSString* returnString = [NSString stringWithFormat:@"%i",index];
    
    FREDispatchStatusEventAsync(freContext, (uint8_t*)"returnPressed", (uint8_t*)[returnString UTF8String]);
}



UIReturnKeyType getReturnKeyTypeFormChar(const char* type){
    if(strcmp(type, "done")==0){
        return UIReturnKeyDone;
    }else if(strcmp(type, "go")==0){
        return UIReturnKeyGo;
    }else if(strcmp(type, "next")==0){
        return UIReturnKeyNext;
    }else if(strcmp(type, "search")==0){
        return UIReturnKeySearch;
    }else {
        return UIReturnKeyDefault;
    }
}



UIKeyboardType getKeyboardTypeFormChar(const char* type){
    if(strcmp(type, "punctuation")==0){
        return UIKeyboardTypeNumbersAndPunctuation;
    }else if(strcmp(type, "url")==0){
        return UIKeyboardTypeURL;
    }else if(strcmp(type, "number")==0){
        return UIKeyboardTypeNumberPad;
    }else if(strcmp(type, "contact")==0){
        return UIKeyboardTypePhonePad;
    }else if(strcmp(type, "email")==0){
        return UIKeyboardTypeEmailAddress;
    }else {
        return UIKeyboardTypeDefault;
    }
}

UITextAutocorrectionType getAutocapitalizationTypeFormChar(const char* type){
    
    if(strcmp(type, "word")==0){
        return UITextAutocapitalizationTypeWords;
    }else if(strcmp(type, "sentence")==0){
        return UITextAutocapitalizationTypeSentences;
    }else if(strcmp(type, "all")==0){
        return UITextAutocapitalizationTypeAllCharacters;
    }else {
        return UITextAutocorrectionTypeNo;
    }
}


-(void)setupTextInput:(UITextField*) textfiel
        withParamsFormFREOBJ: (FREObject) obj{
    
    FREObject returnKeyObj,autocapitalizationTypeObj, keyboardTypeObj,prompTextObj,textObj, autoCorrectObj,displayAsPasswordObj;
    
    FREGetObjectProperty(obj, (const uint8_t *)"returnKeyLabel", &returnKeyObj, NULL);
    FREGetObjectProperty(obj, (const uint8_t *)"softKeyboardType", &keyboardTypeObj, NULL);
    FREGetObjectProperty(obj, (const uint8_t *)"autoCapitalize", &autocapitalizationTypeObj, NULL);
    FREGetObjectProperty(obj, (const uint8_t *)"prompText", &prompTextObj, NULL);
    FREGetObjectProperty(obj, (const uint8_t *)"text", &textObj, NULL);
    
    FREGetObjectProperty(obj, (const uint8_t *)"autoCorrect", &autoCorrectObj, NULL);
    FREGetObjectProperty(obj, (const uint8_t *)"displayAsPassword", &displayAsPasswordObj, NULL);
    
    uint32_t returnKeyTypeLength , autocapitalizationTypeLength , keyboardTypeLength, prompTextLength , textLength , autoCorrect,displayAsPassword;
    const uint8_t* returnKeyType;
    const uint8_t* autocapitalizationType;
    const uint8_t* keyboardType;
    const uint8_t* prompText;
    const uint8_t* text;
    
    FREGetObjectAsUTF8(autocapitalizationTypeObj, &autocapitalizationTypeLength, &autocapitalizationType);
    FREGetObjectAsUTF8(returnKeyObj, &returnKeyTypeLength, &returnKeyType);
    FREGetObjectAsUTF8(keyboardTypeObj, &keyboardTypeLength, &keyboardType);
    FREGetObjectAsUTF8(textObj, &textLength, &text);
    FREGetObjectAsUTF8(prompTextObj, &prompTextLength, &prompText);
    
    FREGetObjectAsBool(autoCorrectObj, &autoCorrect);
    FREGetObjectAsBool(displayAsPasswordObj, &displayAsPassword);
    
    if(displayAsPassword)
        textfiel.secureTextEntry = YES;
    else
        textfiel.secureTextEntry = NO;
    
    if(autoCorrect)
        textfiel.autocorrectionType = UITextAutocorrectionTypeYes;
    else
        textfiel.autocorrectionType = UITextAutocorrectionTypeNo;
    
    [textfiel setText:[NSString stringWithUTF8String:(const char *)text]];
    [textfiel setPlaceholder:[NSString stringWithUTF8String:(const char *)prompText]];
    
    textfiel.keyboardType = getKeyboardTypeFormChar((const char *)keyboardType);
    textfiel.autocapitalizationType = getAutocapitalizationTypeFormChar((const char *)autocapitalizationType);
    textfiel.returnKeyType = getReturnKeyTypeFormChar((const char *)returnKeyType);
}

-(void)showTextInputDialog: (NSString *)title
                   message: (NSString*)message
                textInputs: (FREObject*)textInputs
                   buttons: (FREObject*)buttons
{
    [self dismissWithButtonIndex:0];
    
    NSString* closeLabel=nil;
    
    uint32_t buttons_len;
    FREGetArrayLength(buttons, &buttons_len);
    
    if(buttons_len>0){
        FREObject button0;
        FREGetArrayElementAt(buttons, 0, &button0);
        
        uint32_t button0LabelLength;
        const uint8_t *button0Label;
        FREGetObjectAsUTF8(button0, &button0LabelLength, &button0Label);
        
        closeLabel = [NSString stringWithUTF8String:(char*)button0Label];
    }else{
        closeLabel = NSLocalizedString(@"OK", nil);
    }
    
    BOOL isIOS_5 = [[[UIDevice currentDevice] systemVersion] floatValue]>=5.0;
    
    
    
    //Create our alert.
    if( isIOS_5){
        alert = [[UIAlertView alloc] initWithTitle:title
                                                 message:message
                                                delegate:self
                                       cancelButtonTitle:closeLabel
                                       otherButtonTitles:nil];
    }else{
        alert = [[AlertTextView alloc] initWithTitle:title
                                                   message:message
                                                  delegate:self
                                         cancelButtonTitle:closeLabel
                                         otherButtonTitles:nil];
    }
    

    
    if(buttons_len>1){
        FREObject button1;
        FREGetArrayElementAt(buttons, 1, &button1);
        
        uint32_t button1LabelLength;
        const uint8_t *button1Label;
        FREGetObjectAsUTF8(button1, &button1LabelLength, &button1Label);
        NSString* otherButton=[NSString stringWithUTF8String:(char*)button1Label];
        
        if(otherButton!=nil && ![otherButton isEqualToString:@""]){
            [alert addButtonWithTitle:otherButton];

        }
        
    }
    
    uint32_t textInputs_len;
    FREGetArrayLength(textInputs, &textInputs_len);
    
    int8_t index =0;
    if(message!=nil && ![message isEqualToString:@""])
        index++;
    
    if (textInputs_len > index) {
        UITextField *textField=nil;
        FREObject textObj;
        if(textInputs_len==(index+1)){
            
            if(isIOS_5)
                [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
            else
                [alert setAlertViewStyle:AlertTextViewStylePlainTextInput];
            
            textField = [alert textFieldAtIndex:0];
            
            [textField addTarget:self action:@selector(textFieldDidPressReturn:) forControlEvents:UIControlEventEditingDidEndOnExit];
            
            [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            FREGetArrayElementAt(textInputs, index, &textObj);
            [self setupTextInput:textField withParamsFormFREOBJ:textObj];
            

        }else if(textInputs_len > (index+1)){
            if(isIOS_5)
                [alert setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
            else
                [alert setAlertViewStyle:AlertTextViewStyleLoginAndPasswordInput];
            
            textField = [alert textFieldAtIndex:0];
            [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            FREGetArrayElementAt(textInputs, index, &textObj);
            
            [self setupTextInput:textField withParamsFormFREOBJ:textObj];
            
            textField = [alert textFieldAtIndex:1];
            [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents: UIControlEventEditingChanged];
            FREGetArrayElementAt(textInputs, index+1, &textObj);
            
            [self setupTextInput:textField withParamsFormFREOBJ:textObj];

        }
        
    }
    FREDispatchStatusEventAsync(freContext, (uint8_t*)"nativeDialog_opened", (uint8_t*)"-1");
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void)selectionChanged:(id)sender
                withRow:(NSInteger)row{
    FREDispatchStatusEventAsync(freContext, (const uint8_t *)"nativeListDialog_change", (const uint8_t *)[[NSString stringWithFormat:@"%D",row]UTF8String]);
}

-(void)showSelectPopupWithTitle: (NSString*)title
                        message: (NSString*)message
                        options: (FREObject*)options
                        checked: (FREObject*)checked
                        buttons: (FREObject*)buttons{
    @try {
        FREObjectType type;
        uint32_t checkedEntry = 0;
        FREGetObjectType(checked, &type);
        if(type == FRE_TYPE_NUMBER)
        {
            FREGetObjectAsUint32(checked, &checkedEntry);
        }
        UIToolbar *toolbar = [self initToolbar:buttons];
        picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0, 44.0, 0, 0)];
        picker.showsSelectionIndicator = YES;
        delegate = [[NativeListDelegate alloc] initWithOptions:options target:self action:@selector(selectionChanged:withRow:)];
        picker.delegate = delegate;
        toolbar.barStyle = UIBarStyleBlackOpaque;
        [picker selectRow:checkedEntry inComponent:0 animated:false];
        UIActionSheet *aac = [[UIActionSheet alloc] initWithTitle:title
                                                         delegate:self
                                                cancelButtonTitle:nil
                                           destructiveButtonTitle:nil
                                                otherButtonTitles:nil];
        
        [self dismissWithButtonIndex:0];
        [aac addSubview:toolbar];
        [aac addSubview:picker];
    
        [aac setBounds:CGRectMake(0,0,320, 464)];
    
        [toolbar sizeToFit];
        [toolbar release];
        
        UIWindow* wind= [[[UIApplication sharedApplication] windows] objectAtIndex:0];
        if(!wind){
            NSLog(@"Window is nil");
            FREDispatchStatusEventAsync(freContext, (const uint8_t*)"error", (const uint8_t*)"Window is nil");
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [aac showInView:wind];
            [aac setBounds:CGRectMake(0,0,320, 464)];
        });
        
        actionSheet = aac;
    
    }
    @catch (NSException *exception) {
        FREDispatchStatusEventAsync(freContext, (const uint8_t *)"error", (const uint8_t *)[[exception reason] UTF8String]);
    }
}
-(void)showSelectDialogWithTitle: (NSString*)title
                         message: (NSString*)message
                            type: (uint32_t)displayType
                         options: (FREObject*)options
                         checked: (FREObject*)checked
                         buttons: (FREObject*)buttons{
    
    FREObjectType type;
    if(displayType == 6)
    {
        [self showSelectPopupWithTitle:title message:message options:options checked:checked buttons:buttons];
    }
    else
    {
        [self dismissWithButtonIndex:0];
        
        NSString* closeLabel=nil;
        NSString* otherLabel=nil;
        
        uint32_t buttons_len;
        if(buttons && FREGetArrayLength(buttons, &buttons_len)==FRE_OK){
            if(buttons_len>0){
                FREObject button;
                FREGetArrayElementAt(buttons, 0, &button);
                
                uint32_t buttonLabelLength;
                const uint8_t *buttonLabel;
                if(button){
                    FREGetObjectAsUTF8(button, &buttonLabelLength, &buttonLabel);
                    closeLabel = [NSString stringWithUTF8String:(char*)buttonLabel];
                }
                if(buttons_len>1){
                    FREObject button1;
                    FREGetArrayElementAt(buttons, 1, &button1);
                    if(button1){
                        FREGetObjectAsUTF8(button1, &buttonLabelLength, &buttonLabel);
                        otherLabel = [NSString stringWithUTF8String:(char*)buttonLabel];
                    }
                }
            }
        }
        if(!closeLabel || [closeLabel isEqualToString:@""]){
            closeLabel = [NSLocalizedString(@"Done", nil) autorelease];
        }
        
        
        //Create our alert.
        sbAlert = [[SBTableAlert alloc] initWithTitle:title cancelButtonTitle:closeLabel messageFormat: message];//retain];
        
        
        if(otherLabel && ![otherLabel isEqualToString:@""])
        {
            [sbAlert.view addButtonWithTitle:otherLabel ];
        }
        
        uint32_t options_len; // array length
        if(options && FREGetArrayLength(options, &options_len)==FRE_OK){
            
            FREObject element;
            
            for(int32_t i=0; i<options_len;++i){
                
                // get an element at index
                if(FREGetArrayElementAt(options, i, &element)==FRE_OK){
                    if(element){
                        uint32_t elementLength;
                        const uint8_t *elementLabel;
                        if(FREGetObjectAsUTF8(element, &elementLength, &elementLabel)==FRE_OK){
                            ListItem* item = [ListItem listItemWithText:[NSString stringWithUTF8String:(char*)elementLabel]] ;
                            
                            if(!tableItemList)
                                tableItemList= [[NSMutableArray alloc] init];
                            [tableItemList addObject:item];
                        }
                    }
                }
            }
            
            // options
            if(checked){
                FREGetObjectType(checked, &type);
                if(type == FRE_TYPE_NUMBER){
                    
                    int32_t checkedValue;
                    FREGetObjectAsInt32(checked, &checkedValue);
                    
                    if(checkedValue>=0 || checkedValue< options_len){
                        ListItem* item = [tableItemList objectAtIndex:checkedValue];
                        if(item)
                            item.selected = YES;
                    }
                    [sbAlert setType:SBTableAlertTypeSingleSelect];
                    [sbAlert setStyle:SBTableAlertStyleApple];
                    [sbAlert setDataSource:self];
                    [sbAlert setDelegate:self];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [sbAlert show];
                    });
                    
                    FREDispatchStatusEventAsync(freContext, (uint8_t*)"nativeDialog_opened", (uint8_t*)"-1");
                    
                }else if(type ==FRE_TYPE_VECTOR || type ==FRE_TYPE_ARRAY){
                    
                    uint32_t checkedItems_len; // array length
                    FREGetArrayLength(checked, &checkedItems_len);
                    if(tableItemList && checkedItems_len == options_len){
                        for(int32_t i=checkedItems_len-1; i>=0;i--){
                            // get an element at index
                            FREObject checkedListItem;
                            FREGetArrayElementAt(checked, i, &checkedListItem);
                            if(checkedListItem){
                                uint32_t boolean;
                                if(FREGetObjectAsBool(checkedListItem, &boolean)==FRE_OK){
                                    ListItem* item = [tableItemList objectAtIndex:i];
                                    if(item)
                                        item.selected = boolean;
                                }
                            }
                        }
                    }
                    [self createMultiChoice];
                    
                }
            }else{
                [self createMultiChoice];
            }
        }
    }
}


-(void)createMultiChoice{

    
    [sbAlert setType:SBTableAlertTypeMultipleSelct];
    [sbAlert setDataSource:self];
    [sbAlert setDelegate:self];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [sbAlert show];
    });
    
    FREDispatchStatusEventAsync(freContext, (uint8_t*)"nativeDialog_opened", (uint8_t*)"-1");

}




#pragma mark - SBTableAlertDataSource



- (UITableViewCell *)tableAlert:(SBTableAlert *)tableAlert cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    SBTableAlertCell *cell = [[SBTableAlertCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] ;
    
    if(tableItemList){
        ListItem* item = [tableItemList objectAtIndex:indexPath.row];
        [cell.textLabel setText: [NSString stringWithString:item.text]];
        if(item.selected)
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        else
            [cell setAccessoryType:UITableViewCellAccessoryNone];
	}
  
	return [cell autorelease];
}


- (NSInteger)tableAlert:(SBTableAlert *)tableAlert numberOfRowsInSection:(NSInteger)section{
    if(tableItemList)
        return [tableItemList count];
    else
        return 0;
}





#pragma mark - SBTableAlertDelegate


- (void)tableAlert:(SBTableAlert *)tableAlert didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *returnString =nil;
    if (tableAlert.type == SBTableAlertTypeMultipleSelct) {
		UITableViewCell *cell = [tableAlert.tableView cellForRowAtIndexPath:indexPath];
		if (cell.accessoryType == UITableViewCellAccessoryNone){
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            returnString = [NSString stringWithFormat:@"%d_true",[indexPath row]];
        }else{
			[cell setAccessoryType:UITableViewCellAccessoryNone];
            returnString = [NSString stringWithFormat:@"%d_false",[indexPath row]];
		}
		[tableAlert.tableView deselectRowAtIndexPath:indexPath animated:YES];
	}else
        returnString = [NSString stringWithFormat:@"%d", [indexPath row]];
    
    FREDispatchStatusEventAsync(freContext, (uint8_t*)"nativeListDialog_change", (uint8_t*)[returnString UTF8String]);
     
}




- (void)tableAlert:(SBTableAlert *)tableAlert didDismissWithButtonIndex:(NSInteger)buttonIndex{

    NSString *buttonID = [NSString stringWithFormat:@"%d", buttonIndex];
    uint8_t* event = (uint8_t*)"nativeDialog_closed";
    if(cancelable && buttonIndex == 1)
    {
        event = (uint8_t*)"nativeDialog_canceled";
    }
    FREDispatchStatusEventAsync(freContext, event, (uint8_t*)[buttonID UTF8String]);
    //Cleanup references.
    
    [tableItemList release];
    tableItemList = nil;
    [sbAlert release];
    sbAlert = nil;
    

}









#pragma mark - All


-(void)setCancelable:(uint32_t)can{
    cancelable = can;
}
-(void)dismissWithButtonIndex:(int32_t)index{

    [popover dismissPopoverAnimated:YES];
    [actionSheet dismissWithClickedButtonIndex:index animated:YES];
    [alert dismissWithClickedButtonIndex:index animated:YES];
    [sbAlert.view dismissWithClickedButtonIndex:index animated:YES];
}
-(UIView*)getView{
    UIView *u;
    if(popover ){
        u = popover.contentViewController.view;
    }else if(alert && alert.isHidden==NO){
        u = alert;
    }
    else if(sbAlert && sbAlert.view.isHidden==NO){
        u = sbAlert.view;
    }
    return u;
}

-(void)shake{
    
    UIView* u= [self getView];
    if(u){
        CGRect r = u.frame;
        oldX = r.origin.x;
        r.origin.x = r.origin.x - r.origin.x * 0.1;
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        [UIView beginAnimations:nil context:context];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:.1f];
        [UIView setAnimationRepeatCount:5];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationFinished:)];
        [UIView setAnimationRepeatAutoreverses:NO];
        [u setFrame:r];
        
        [UIView commitAnimations];
    }
}
-(void)animationFinished:(NSString*)animationID{
    UIView* u= [self getView];
    CGRect r = u.frame;
    r.origin.x = oldX;
    [u setFrame:r];
}

-(void)updateMessage:(NSString*)message
{
    #ifdef MYDEBUG
        NSLog(@"updateMessage to %@",message);
    #endif
    
    [self performSelectorOnMainThread: @selector(updateMessageWithSt:)
                           withObject: message waitUntilDone:NO];
}
- (void) updateMessageWithSt:(NSString*)message {
    if(sbAlert)
        sbAlert.view.message = message;
    else if(alert)
        alert.message = message;
}
-(void)updateTitle:(NSString*)title{
    #ifdef MYDEBUG
        NSLog(@"updateTitle to %@",title);
    #endif
    
    [self performSelectorOnMainThread: @selector(updateTitleWithSt:)
                           withObject: title waitUntilDone:NO];
    
}
- (void) updateTitleWithSt:(NSString*)title {
    if(sbAlert)
        sbAlert.view.title =title;
    else if(alert){
        [alert setTitle:title];
    }
}

-(BOOL)isShowing{
    #ifdef MYDEBUG
        NSLog(@"isShowing");
    #endif
    if(sbAlert){
        if(sbAlert.view.isHidden==NO){
            return YES;
        }else
            return NO;
    }
    else if(alert){
        return [alert isVisible];
    }
    return NO;
}







#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    BOOL isIOS_5OrLater = [[[UIDevice currentDevice] systemVersion] floatValue]>=5.0;
    if(isIOS_5OrLater){
        if([alertView alertViewStyle]!=UIAlertViewStyleDefault && [alertView alertViewStyle]!=AlertTextViewStyleDefault){
            [[alertView textFieldAtIndex:0] resignFirstResponder];
            if([alertView alertViewStyle]==UIAlertViewStyleLoginAndPasswordInput || [alertView alertViewStyle]==AlertTextViewStyleLoginAndPasswordInput){
                [[alertView textFieldAtIndex:1] resignFirstResponder];
            }
        }
    }
    //Create our params to pass to the event dispatcher.
    NSString *buttonID = [NSString stringWithFormat:@"%d", buttonIndex];
    FREDispatchStatusEventAsync(freContext, (uint8_t*)"nativeDialog_closed", (uint8_t*)[buttonID UTF8String]);
    
    //Cleanup references.
    [alert release];
    alert = nil;

    [progressView release];
    progressView = nil;
    
}
/*
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    //Create our params to pass to the event dispatcher.
    NSString *buttonID = [NSString stringWithFormat:@"%d", buttonIndex];
    FREDispatchStatusEventAsync(freContext, (uint8_t*)"nativeDialog_closed", (uint8_t*)[buttonID UTF8String]);
    
    //Cleanup references.
    [alertView release];
    alert = NULL;
    
    if(progressView){
        [progressView release];
        progressView = nil;
    }

}
*/

-(void)dealloc{
    
    picker.delegate = nil;
    [picker release];
    if(view)
    {
        [view release];
        view = nil;
    }
    NSLog(@"main dealloc");
    [tableItemList release];
    [delegate release];
    popover.delegate = nil;
    [popover release];
    [alert release];
    [actionSheet release];
    [sbAlert release];
    [progressView release];
    
    freContext = nil;
    [super dealloc];
}

@end
