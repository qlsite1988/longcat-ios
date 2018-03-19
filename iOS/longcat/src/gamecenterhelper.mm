#import <GameKit/GameKit.h>

#include <QtCore/QDebug>

#include "gamecenterhelper.h"

const QString GameCenterHelper::GC_LEADERBOARD_ID("longcat.leaderboard.score");

GameCenterHelper *GameCenterHelper::Instance = NULL;

@interface GameCenterControllerDelegate : NSObject<GKGameCenterControllerDelegate>

- (id)init;
- (void)dealloc;
- (void)showLeaderboard;
- (void)reportScore:(int)value;

@property (nonatomic, assign) BOOL GameCenterEnabled;

@end

@implementation GameCenterControllerDelegate

@synthesize GameCenterEnabled;

- (id)init
{
    self = [super init];

    if (self) {
        GameCenterEnabled = NO;

        UIViewController * __block root_view_controller = nil;

        [[[UIApplication sharedApplication] windows] enumerateObjectsUsingBlock:^(UIWindow * _Nonnull window, NSUInteger, BOOL * _Nonnull stop) {
            root_view_controller = [window rootViewController];

            *stop = (root_view_controller != nil);
        }];

        GKLocalPlayer *local_player = [GKLocalPlayer localPlayer];

        local_player.authenticateHandler = ^(UIViewController *view_controller, NSError *error) {
            if (error != nil) {
                qWarning() << QString::fromNSString([error localizedDescription]);
            } else {
                if (view_controller != nil) {
                    [root_view_controller presentViewController:view_controller animated:YES completion:nil];
                } else if (local_player.isAuthenticated) {
                    GameCenterEnabled = YES;

                    GameCenterHelper::setGameCenterEnabled(true);
                } else {
                    GameCenterEnabled = NO;

                    GameCenterHelper::setGameCenterEnabled(false);
                }
            }
        };
    }

    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)showLeaderboard
{
    if (GameCenterEnabled) {
        UIViewController * __block root_view_controller = nil;

        [[[UIApplication sharedApplication] windows] enumerateObjectsUsingBlock:^(UIWindow * _Nonnull window, NSUInteger, BOOL * _Nonnull stop) {
            root_view_controller = [window rootViewController];

            *stop = (root_view_controller != nil);
        }];

        GKGameCenterViewController *gc_view_controller = [[GKGameCenterViewController alloc] init];

        gc_view_controller.gameCenterDelegate    = self;
        gc_view_controller.viewState             = GKGameCenterViewControllerStateLeaderboards;
        gc_view_controller.leaderboardIdentifier = GameCenterHelper::GC_LEADERBOARD_ID.toNSString();

        [root_view_controller presentViewController:gc_view_controller animated:YES completion:nil];
    }
}

- (void)reportScore:(int)value
{
    GKScore *score = [[GKScore alloc] initWithLeaderboardIdentifier:GameCenterHelper::GC_LEADERBOARD_ID.toNSString()];

    score.value = value;

    [GKScore reportScores:@[score] withCompletionHandler:^(NSError *error) {
        if (error != nil) {
            qWarning() << QString::fromNSString([error localizedDescription]);
        }
    }];
}

-(void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

GameCenterHelper::GameCenterHelper(QObject *parent) : QObject(parent)
{
    Initialized                          = false;
    GameCenterEnabled                    = false;
    Instance                             = this;
    GameCenterControllerDelegateInstance = NULL;
}

GameCenterHelper::~GameCenterHelper()
{
    if (Initialized) {
        [GameCenterControllerDelegateInstance release];
    }
}

bool GameCenterHelper::gameCenterEnabled() const
{
    return GameCenterEnabled;
}

void GameCenterHelper::initialize()
{
    if (!Initialized) {
        GameCenterControllerDelegateInstance = [[GameCenterControllerDelegate alloc] init];

        Initialized = true;
    }
}

void GameCenterHelper::showLeaderboard()
{
    if (Initialized) {
        [GameCenterControllerDelegateInstance showLeaderboard];
    }
}

void GameCenterHelper::reportScore(int score)
{
    if (Initialized) {
        [GameCenterControllerDelegateInstance reportScore:score];
    }
}

void GameCenterHelper::setGameCenterEnabled(const bool &enabled)
{
    Instance->GameCenterEnabled = enabled;

    emit Instance->gameCenterEnabledChanged(Instance->GameCenterEnabled);
}
