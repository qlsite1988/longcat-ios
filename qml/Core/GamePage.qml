import QtQuick 2.12
import QtQuick.Controls 2.5
import QtMultimedia 5.12

import "Game"

Item {
    id: gamePage

    readonly property bool appInForeground:    Qt.application.state === Qt.ApplicationActive
    readonly property bool pageActive:         StackView.status === StackView.Active
    readonly property bool interstitialActive: AdMobHelper.interstitialActive
    readonly property bool gamePaused:         !appInForeground || !pageActive || interstitialActive || shareViewActive || gameEnded

    readonly property int bannerViewHeight:    AdMobHelper.bannerViewHeight
    readonly property int maxGameDifficulty:   20

    property bool shareViewActive:             false
    property bool gameRunning:                 true
    property bool gameEnded:                   false

    property int gameDifficulty:               0
    property int gameElapsedTime:              0
    property int gameScore:                    0

    onGameRunningChanged: {
        if (gameRunning) {
            pressHintImage.visible = true;
        } else {
            pressHintImage.visible = false;
        }
    }

    onGameEndedChanged: {
        if (gameEnded) {
            pressHintImage.visible = false;
        }
    }

    function captureImage() {
        if (!gamePage.grabToImage(function (result) {
            if (result.saveToFile(ShareHelper.imageFilePath)) {
                shareViewActive = true;

                ShareHelper.showShareToView(ShareHelper.imageFilePath);
            } else {
                console.error("saveToFile() failed");
            }
        })) {
            console.error("grabToImage() failed");
        }
    }

    SoundEffect {
        id:     musicSoundEffect
        volume: 0.5
        loops:  SoundEffect.Infinite
        source: "qrc:/resources/sound/game/music.wav"

        readonly property bool playbackEnabled: !gamePage.gamePaused

        onPlaybackEnabledChanged: {
            if (playbackEnabled) {
                play();
            } else {
                stop();
            }
        }
    }

    Audio {
        id:     gameOverAudio
        volume: 1.0
        source: "qrc:/resources/sound/game/game_over.wav"

        onError: {
            console.error(errorString);
        }
    }

    FontLoader {
        id:     arcadeClassicFont
        source: "qrc:/resources/fonts/game/arcade_classic.ttf"
    }

    Rectangle {
        id:           backgroundRectangle
        anchors.fill: parent
        color:        "black"

        Image {
            id:               backgroundImage
            anchors.centerIn: parent
            width:            Math.floor(imageWidth(sourceSize.width, sourceSize.height, parent.width, parent.height))
            height:           Math.floor(imageHeight(sourceSize.width, sourceSize.height, parent.width, parent.height))
            source:           "qrc:/resources/images/game/background.png"
            fillMode:         Image.PreserveAspectCrop

            readonly property real visibleWidth: parent.width
            readonly property real imageScale:   sourceSize.width > 0.0 ? paintedWidth / sourceSize.width : 1.0

            function imageWidth(src_width, src_height, dst_width, dst_height) {
                if (src_width > 0 && src_height > 0 && dst_width > 0 && dst_height > 0) {
                    if (dst_width / dst_height < src_width / src_height) {
                        return src_width * dst_height / src_height;
                    } else {
                        return dst_width;
                    }
                } else {
                    return 0;
                }
            }

            function imageHeight(src_width, src_height, dst_width, dst_height) {
                if (src_width > 0 && src_height > 0 && dst_width > 0 && dst_height > 0) {
                    if (dst_width / dst_height < src_width / src_height) {
                        return dst_height;
                    } else {
                        return src_height * dst_width / src_width;
                    }
                } else {
                    return 0;
                }
            }

            AnimatedLayer {
                id:           cloudsLayer
                anchors.fill: parent
                z:            1
                running:      gamePage.gameRunning
                paused:       gamePage.gamePaused
                speed:        0.125 * (backgroundImage.visibleWidth / 1.0) * (0.5 + (gamePage.gameDifficulty / gamePage.maxGameDifficulty) / 4.0)
                imageSource:  "qrc:/resources/images/game/layer_clouds.png"
            }

            AnimatedLayer {
                id:           hillsLayer
                anchors.fill: parent
                z:            2
                running:      gamePage.gameRunning
                paused:       gamePage.gamePaused
                speed:        0.25 * (backgroundImage.visibleWidth / 1.0) * (0.5 + (gamePage.gameDifficulty / gamePage.maxGameDifficulty) / 4.0)
                imageSource:  "qrc:/resources/images/game/layer_hills.png"
            }

            AnimatedLayer {
                id:           forefrontLayer
                anchors.fill: parent
                z:            3
                running:      gamePage.gameRunning
                paused:       gamePage.gamePaused
                speed:        0.5 * (backgroundImage.visibleWidth / 1.0) * (0.5 + (gamePage.gameDifficulty / gamePage.maxGameDifficulty) / 4.0)
                imageSource:  "qrc:/resources/images/game/layer_forefront.png"
            }

            AnimatedLayer {
                id:           groundLayer
                anchors.fill: parent
                z:            4
                running:      gamePage.gameRunning
                paused:       gamePage.gamePaused
                speed:        1.0 * (backgroundImage.visibleWidth / 1.0) * (0.5 + (gamePage.gameDifficulty / gamePage.maxGameDifficulty) / 4.0)
                imageSource:  "qrc:/resources/images/game/layer_ground.png"
            }

            AnimatedObjectsLayer {
                id:                    objectsLayer
                anchors.fill:          parent
                z:                     5
                running:               gamePage.gameRunning
                paused:                gamePage.gamePaused
                objectsElevation:      172
                objectsCount:          12 + ((gamePage.gameDifficulty / gamePage.maxGameDifficulty) * 5)
                speed:                 1.0 * (backgroundImage.visibleWidth / 1.0) * (0.5 + (gamePage.gameDifficulty / gamePage.maxGameDifficulty) / 4.0)
                edibleObjectsHandicap: 1.0 * (1.0 - (gamePage.gameDifficulty / gamePage.maxGameDifficulty) / 2.0)
                imageSource:           "qrc:/resources/images/game/layer_objects.png"
            }

            Cat {
                id:                       cat
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom:           parent.bottom
                anchors.bottomMargin:     80 * imageScale
                z:                        6
                paused:                   gamePage.gamePaused
                stretchTo:                192
                energy:                   100
                maxEnergy:                100
                imageScale:               backgroundImage.imageScale
                intersectionShare:        0.25

                onAliveChanged: {
                    if (!alive) {
                        gamePage.gameEnded = true;

                        gameOverAudio.play();

                        GameCenterHelper.reportScore(gamePage.gameScore);
                    }
                }

                onCatEnlarged: {
                    objectsLayer.checkCatIntersections(cat);
                }

                onCatConsumedObject: {
                    if (objectEnergy > 0) {
                        gamePage.gameScore = gamePage.gameScore + objectEnergy;
                    }
                }

                onCatDead: {
                    catRIPAnimation.start();

                    catRIPImage.visible = true;
                }
            }

            Image {
                id:                       catRIPImage
                anchors.horizontalCenter: parent.horizontalCenter
                y:                        parent.height - height - cat.anchors.bottomMargin
                z:                        7
                width:                    sourceSize.width  * backgroundImage.imageScale
                height:                   sourceSize.height * backgroundImage.imageScale
                source:                   "qrc:/resources/images/game/cat_rip.png"
                fillMode:                 Image.Stretch
                visible:                  false

                NumberAnimation {
                    id:       catRIPAnimation
                    target:   catRIPImage
                    property: "y"
                    from:     0 - catRIPImage.height
                    to:       catRIPImage.parent.height - catRIPImage.height - cat.anchors.bottomMargin
                    duration: 250
                }
            }
        }

        Column {
            anchors.top:       parent.top
            anchors.left:      parent.left
            anchors.topMargin: Math.max(gamePage.bannerViewHeight + 4 * backgroundImage.imageScale,
                                        34 * backgroundImage.imageScale)
            z:                 1
            spacing:           4 * backgroundImage.imageScale

            Text {
                id:                  timerText
                anchors.left:        parent.left
                text:                textText(gamePage.gameElapsedTime)
                color:               "blue"
                font.pointSize:      32
                font.family:         arcadeClassicFont.name
                horizontalAlignment: Text.AlignLeft
                verticalAlignment:   Text.AlignVCenter

                function textText(elapsed_time) {
                    var hrs = Math.floor(elapsed_time / 1000 / 3600).toString(10);
                    var mns = Math.floor((elapsed_time / 1000 - hrs * 3600) / 60).toString(10);
                    var scs = Math.floor(elapsed_time / 1000 - hrs * 3600 - mns * 60).toString(10);

                    if (hrs.length < 2) {
                        hrs = "0" + hrs;
                    }
                    if (mns.length < 2) {
                        mns = "0" + mns;
                    }
                    if (scs.length < 2) {
                        scs = "0" + scs;
                    }

                    return "%1:%2:%3".arg(hrs).arg(mns).arg(scs);
                }
            }

            Text {
                id:                  playerRankText
                anchors.left:        parent.left
                text:                "#%1".arg(GameCenterHelper.playerRank)
                color:               "red"
                font.pointSize:      32
                font.family:         arcadeClassicFont.name
                horizontalAlignment: Text.AlignLeft
                verticalAlignment:   Text.AlignVCenter
                visible:             GameCenterHelper.playerRank !== 0 && GameCenterHelper.playerScore !== 0
            }
        }

        Column {
            anchors.top:       parent.top
            anchors.right:     parent.right
            anchors.topMargin: Math.max(gamePage.bannerViewHeight + 4 * backgroundImage.imageScale,
                                        34 * backgroundImage.imageScale)
            z:                 1
            spacing:           4 * backgroundImage.imageScale

            Text {
                id:                  scoreText
                anchors.right:       parent.right
                text:                textText(gamePage.gameScore)
                color:               "blue"
                font.pointSize:      32
                font.family:         arcadeClassicFont.name
                horizontalAlignment: Text.AlignRight
                verticalAlignment:   Text.AlignVCenter

                function textText(game_score) {
                    var score = game_score.toString(10);

                    while (score.length < 6) {
                        score = "0" + score;
                    }

                    return score;
                }
            }

            Text {
                id:                  playerScoreText
                anchors.right:       parent.right
                text:                textText(GameCenterHelper.playerScore)
                color:               "red"
                font.pointSize:      32
                font.family:         arcadeClassicFont.name
                horizontalAlignment: Text.AlignRight
                verticalAlignment:   Text.AlignVCenter
                visible:             GameCenterHelper.playerRank !== 0 && GameCenterHelper.playerScore !== 0

                function textText(player_score) {
                    var score = player_score.toString(10);

                    while (score.length < 6) {
                        score = "0" + score;
                    }

                    return score;
                }
            }
        }

        Rectangle {
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            z:                      1
            width:                  parent.width  / 10
            height:                 parent.height / 3
            radius:                 8 * backgroundImage.imageScale
            border.width:           4 * backgroundImage.imageScale
            border.color:           "black"

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color:    "green"
                }

                GradientStop {
                    position: 0.5
                    color:    "yellow"
                }

                GradientStop {
                    position: 1.0
                    color:    "red"
                }
            }

            Rectangle {
                anchors.left:    parent.left
                anchors.right:   parent.right
                anchors.top:     parent.top
                anchors.margins: parent.border.width
                height:          cat.maxEnergy > 0 ? (parent.height - parent.border.width * 2) *
                                                     (1.0 - cat.energy / cat.maxEnergy) :
                                                     parent.height - parent.border.width * 2
                color:           "lightgray"
            }
        }

        Image {
            id:               pressHintImage
            anchors.centerIn: parent
            z:                1
            width:            sourceSize.width  * backgroundImage.imageScale
            height:           sourceSize.height * backgroundImage.imageScale
            source:           "qrc:/resources/images/game/hand.png"
            fillMode:         Image.PreserveAspectFit

            SequentialAnimation {
                loops:   Animation.Infinite
                running: pressHintImage.visible

                NumberAnimation {
                    target:   pressHintImage
                    property: "opacity"
                    from:     1.0
                    to:       0.0
                    duration: 250
                }

                NumberAnimation {
                    target:   pressHintImage
                    property: "opacity"
                    from:     0.0
                    to:       1.0
                    duration: 250
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z:            2

            onClicked: {
                pressHintImage.visible = false;

                cat.enlargeCat();
            }
        }

        Image {
            anchors.left:         parent.left
            anchors.bottom:       parent.bottom
            anchors.leftMargin:   8  * backgroundImage.imageScale
            anchors.bottomMargin: 16 * backgroundImage.imageScale
            z:                    5
            width:                sourceSize.width  * backgroundImage.imageScale
            height:               sourceSize.height * backgroundImage.imageScale
            source:               "qrc:/resources/images/game/button_back.png"
            fillMode:             Image.PreserveAspectFit

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    if (ReachabilityHelper.internetConnected) {
                        StoreHelper.requestReview();
                    }

                    mainStackView.pop(StackView.Immediate);
                }
            }
        }

        Column {
            anchors.right:        parent.right
            anchors.bottom:       parent.bottom
            anchors.rightMargin:  8  * backgroundImage.imageScale
            anchors.bottomMargin: 16 * backgroundImage.imageScale
            z:                    5
            spacing:              16 * backgroundImage.imageScale

            Image {
                width:    sourceSize.width  * backgroundImage.imageScale
                height:   sourceSize.height * backgroundImage.imageScale
                source:   "qrc:/resources/images/game/button_capture.png"
                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        gamePage.captureImage();
                    }
                }
            }

            Image {
                width:    sourceSize.width  * backgroundImage.imageScale
                height:   sourceSize.height * backgroundImage.imageScale
                source:   "qrc:/resources/images/game/button_restart.png"
                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        gamePage.gameRunning     = false;
                        gamePage.gameEnded       = false;
                        gamePage.gameDifficulty  = 0;
                        gamePage.gameElapsedTime = 0;
                        gamePage.gameScore       = 0;

                        catRIPAnimation.stop();

                        catRIPImage.visible = false;

                        cat.reviveCat();

                        gamePage.gameRunning = true;

                        if (Math.random() < 0.30) {
                            AdMobHelper.showInterstitial();
                        }
                    }
                }
            }
        }
    }

    Timer {
        id:       gameTimer
        running:  !gamePage.gamePaused
        interval: 1000
        repeat:   true

        onTriggered: {
            gamePage.gameElapsedTime = gamePage.gameElapsedTime + interval;

            cat.energy = cat.energy - 5;

            gamePage.gameDifficulty = Math.min(gamePage.gameElapsedTime / 1000 / 5, gamePage.maxGameDifficulty);
        }
    }

    Connections {
        target: ShareHelper

        onShareToViewCompleted: {
            if (gamePage) {
                shareViewActive = false;
            }
        }
    }
}
