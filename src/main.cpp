#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QFont>
#include <QIcon>
#include <QDebug>

#include "services/MusicService.h"
#include "services/SourceManager.h"
#include "player/MusicPlayer.h"
#include "download/DownloadManager.h"
#include "models/SettingsModel.h"
#include "bridge/AppBridge.h"

#include <QFile>
#include <QTextStream>

void customLogHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg) {
    Q_UNUSED(type);
    Q_UNUSED(context);
    static QFile logFile("app.log");
    if (!logFile.isOpen()) {
        logFile.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text);
    }
    QTextStream out(&logFile);
    out << msg << "\n";
    out.flush();
}

int main(int argc, char *argv[]) {
    qInstallMessageHandler(customLogHandler);
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
#endif

    QApplication app(argc, argv);
    app.setApplicationName("MusicDownloader");
    app.setOrganizationName("MusicDownloader");
    app.setApplicationVersion("1.0.0");
    app.setWindowIcon(QIcon(":/icons/app.ico"));

    // Set modern clean QML style
    QQuickStyle::setStyle("Basic");

    // Initialize backend services
    MusicService musicService;
    MusicPlayer musicPlayer(&musicService);
    DownloadManager downloadManager(&musicService);
    SourceManager sourceManager;
    musicService.setSourceManager(&sourceManager);

    // Save configurations on exit
    QObject::connect(&app, &QCoreApplication::aboutToQuit, [&]() {
        SettingsModel::instance().save();
        sourceManager.saveSources();
    });

    // Bridge C++ backend with QML UI
    AppBridge bridge(&musicService, &musicPlayer, &downloadManager, &sourceManager);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("backend", &bridge);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );

    engine.load(QUrl("qrc:/qml/Main.qml"));

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML root object from qrc:/qml/Main.qml";
        return -1;
    }

    return app.exec();
}
