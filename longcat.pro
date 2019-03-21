TEMPLATE = app
TARGET = longcat

QT += quick quickcontrols2 sql multimedia
CONFIG += c++11

DEFINES += QT_DEPRECATED_WARNINGS

SOURCES += src/main.cpp

OBJECTIVE_SOURCES += \
    src/sharehelper.mm \
    src/admobhelper.mm \
    src/storehelper.mm \
    src/gamecenterhelper.mm \
    src/reachabilityhelper.mm

HEADERS += \
    src/sharehelper.h \
    src/admobhelper.h \
    src/storehelper.h \
    src/gamecenterhelper.h \
    src/reachabilityhelper.h

RESOURCES += \
    qml.qrc \
    resources.qrc \
    translations.qrc

TRANSLATIONS += \
    translations/longcat_ru.ts \
    translations/longcat_ja.ts

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

ios {
    CONFIG += qtquickcompiler

    INCLUDEPATH += $$PWD/ios/frameworks
    DEPENDPATH += $$PWD/ios/frameworks

    LIBS += -F $$PWD/ios/frameworks \
            -framework GoogleMobileAds \
            -framework AdSupport \
            -framework CFNetwork \
            -framework CoreMotion \
            -framework CoreTelephony \
            -framework GameKit \
            -framework GLKit \
            -framework MediaPlayer \
            -framework MessageUI \
            -framework StoreKit \
            -framework SystemConfiguration

    QMAKE_APPLE_DEVICE_ARCHS = arm64
    QMAKE_INFO_PLIST = ios/Info.plist
}
