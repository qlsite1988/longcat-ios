#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

#include <QtCore/QDebug>

#include "gamecenterhelper.h"

const QString GameCenterHelper::GC_LEADERBOARD_ID("longcat.leaderboard.score");

@interface GameCenterControllerDelegate : NSObject<GKGameCenterControllerDelegate>

- (id)init;
- (void)authenticate;
- (void)showLeaderboard;
- (void)reportScore:(int)value;

@end

@implementation GameCenterControllerDelegate
{
    BOOL GameCenterEnabled;
}

- (id)init
{
    self = [super init];

    if (self) {
        GameCenterEnabled = NO;
    }

    return self;
}

- (void)authenticate
{
    UIViewController * __block root_view_controller = nil;

    [UIApplication.sharedApplication.windows enumerateObjectsUsingBlock:^(UIWindow * _Nonnull window, NSUInteger, BOOL * _Nonnull stop) {
        root_view_controller = window.rootViewController;

        *stop = (root_view_controller != nil);
    }];

    GKLocalPlayer *local_player = GKLocalPlayer.localPlayer;

    if (@available(iOS 7, *)) {
        local_player.authenticateHandler = ^(UIViewController *view_controller, NSError *error) {
            if (error != nil) {
                qWarning() << QString::fromNSString(error.localizedDescription);

                GameCenterEnabled = NO;

                GameCenterHelper::setGameCenterEnabled(GameCenterEnabled);
            } else {
                if (view_controller != nil) {
                    [root_view_controller presentViewController:view_controller animated:YES completion:nil];
                } else if (local_player.isAuthenticated) {
                    GameCenterEnabled = YES;

                    GameCenterHelper::setGameCenterEnabled(GameCenterEnabled);

                    GKLeaderboard *leaderboard = [[GKLeaderboard alloc] init];

                    leaderboard.identifier = GameCenterHelper::GC_LEADERBOARD_ID.toNSString();

                    [leaderboard loadScoresWithCompletionHandler:^(NSArray*, NSError *error) {
                        if (error != nil) {
                            qWarning() << QString::fromNSString(error.localizedDescription);
                        } else {
                            if (leaderboard.localPlayerScore != nil) {
                                GameCenterHelper::setPlayerScore(static_cast<int>(leaderboard.localPlayerScore.value));
                                GameCenterHelper::setPlayerRank(static_cast<int>(leaderboard.localPlayerScore.rank));
                            }
                        }

                        [leaderboard autorelease];
                    }];
                } else {
                    GameCenterEnabled = NO;

                    GameCenterHelper::setGameCenterEnabled(GameCenterEnabled);
                }
            }
        };
    } else {
        assert(0);
    }
}

- (void)showLeaderboard
{
    if (GameCenterEnabled) {
        UIViewController * __block root_view_controller = nil;

        [UIApplication.sharedApplication.windows enumerateObjectsUsingBlock:^(UIWindow * _Nonnull window, NSUInteger, BOOL * _Nonnull stop) {
            root_view_controller = window.rootViewController;

            *stop = (root_view_controller != nil);
        }];

        if (@available(iOS 7, *)) {
            GKGameCenterViewController *gc_view_controller = [[[GKGameCenterViewController alloc] init] autorelease];

            gc_view_controller.gameCenterDelegate    = self;
            gc_view_controller.viewState             = GKGameCenterViewControllerStateLeaderboards;
            gc_view_controller.leaderboardIdentifier = GameCenterHelper::GC_LEADERBOARD_ID.toNSString();

            [root_view_controller presentViewController:gc_view_controller animated:YES completion:nil];
        } else {
            assert(0);
        }
    }
}

- (void)reportScore:(int)value
{
    if (GameCenterEnabled) {
        if (value > 0) {
            GKScore *score = [[[GKScore alloc] initWithLeaderboardIdentifier:GameCenterHelper::GC_LEADERBOARD_ID.toNSString()] autorelease];

            score.value = value;

            if (@available(iOS 7, *)) {
                [GKScore reportScores:@[score] withCompletionHandler:^(NSError *error) {
                    if (error != nil) {
                        qWarning() << QString::fromNSString(error.localizedDescription);
                    } else {
                        GKLeaderboard *leaderboard = [[GKLeaderboard alloc] init];

                        leaderboard.identifier = GameCenterHelper::GC_LEADERBOARD_ID.toNSString();

                        [leaderboard loadScoresWithCompletionHandler:^(NSArray*, NSError *error) {
                            if (error != nil) {
                                qWarning() << QString::fromNSString(error.localizedDescription);
                            } else {
                                if (leaderboard.localPlayerScore != nil) {
                                    GameCenterHelper::setPlayerScore(static_cast<int>(leaderboard.localPlayerScore.value));
                                    GameCenterHelper::setPlayerRank(static_cast<int>(leaderboard.localPlayerScore.rank));
                                }
                            }

                            [leaderboard autorelease];
                        }];
                    }
                }];
            } else {
                assert(0);
            }
        }
    }
}

-(void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController API_AVAILABLE(ios(6))
{
    [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

GameCenterHelper::GameCenterHelper(QObject *parent) : QObject(parent)
{
    GameCenterEnabled                    = false;
    PlayerScore                          = 0;
    PlayerRank                           = 0;
    GameCenterControllerDelegateInstance = [[GameCenterControllerDelegate alloc] init];
}

GameCenterHelper::~GameCenterHelper() noexcept
{
    [GameCenterControllerDelegateInstance release];
}

GameCenterHelper &GameCenterHelper::GetInstance()
{
    static GameCenterHelper instance;

    return instance;
}

bool GameCenterHelper::gameCenterEnabled() const
{
    return GameCenterEnabled;
}

int GameCenterHelper::playerScore() const
{
    return PlayerScore;
}

int GameCenterHelper::playerRank() const
{
    return PlayerRank;
}

void GameCenterHelper::authenticate()
{
    [GameCenterControllerDelegateInstance authenticate];
}

void GameCenterHelper::showLeaderboard()
{
    [GameCenterControllerDelegateInstance showLeaderboard];
}

void GameCenterHelper::reportScore(int score)
{
    [GameCenterControllerDelegateInstance reportScore:score];
}

void GameCenterHelper::setGameCenterEnabled(bool enabled)
{
    GetInstance().GameCenterEnabled = enabled;

    emit GetInstance().gameCenterEnabledChanged(GetInstance().GameCenterEnabled);
}

void GameCenterHelper::setPlayerScore(int score)
{
    GetInstance().PlayerScore = score;

    emit GetInstance().playerScoreChanged(GetInstance().PlayerScore);
}

void GameCenterHelper::setPlayerRank(int rank)
{
    GetInstance().PlayerRank = rank;

    emit GetInstance().playerRankChanged(GetInstance().PlayerRank);
}
