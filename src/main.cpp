#include "mymodel.h"
#include "weatherdata.h"
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);

    qmlRegisterType<IndexData>("an.weather", 1, 0, "IndexData");
    qmlRegisterType<WeatherData>("an.weather", 1, 0, "WeatherData");
    qmlRegisterType<MyModel>("an.model", 1, 0, "MyModel");

    QQmlApplicationEngine engine;
    MyModel *myModel = new MyModel();
    engine.rootContext()->setContextProperty("myModel", myModel);
    engine.load(QUrl(QLatin1String("qrc:/src/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
