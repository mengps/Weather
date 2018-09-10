#ifndef MYMODEL_H
#define MYMODEL_H
#include <QObject>
#include <QQmlListProperty>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkAccessManager>
#include <QGeoPositionInfoSource>
#include "myjsonparse.h"

class MyModelPrivate;
class MyModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QQmlListProperty<IndexData> indexData READ indexData NOTIFY indexDataChanged)
    Q_PROPERTY(QQmlListProperty<WeatherData> weatherData READ weatherData NOTIFY weatherDataChanged)
    Q_PROPERTY(QString city READ city WRITE setCity NOTIFY cityChanged)
    Q_PROPERTY(QString pm25 READ pm25 WRITE setPm25 NOTIFY pm25Changed)
    Q_PROPERTY(bool ready READ ready WRITE setReady NOTIFY readyChanged)

public:
    MyModel(QObject *parent = nullptr);
    ~MyModel();

    QQmlListProperty<IndexData> indexData();
    QQmlListProperty<WeatherData> weatherData();

    QString city() const;
    QString pm25() const;
    bool ready() const;
    void readSettings();
    void writeSettings();

public slots:
    void downRefresh(); //下拉刷新
    void setReady(bool arg);
    void setCity(const QString &arg);
    void setPm25(const QString &arg);
    void updatePosition(QGeoPositionInfo gpsPos);
    void updateWeather(QNetworkReply *reply);

protected:
    void timerEvent(QTimerEvent *event);

signals:
    void indexDataChanged();
    void weatherDataChanged();
    void readyChanged();
    void cityChanged();
    void pm25Changed();

private:
    MyModelPrivate *m_dptr;
    QGeoPositionInfoSource *m_geoPosSrc;
    QNetworkAccessManager *m_netManager;
    MyJsonParse m_parse;
    QString m_api;
    bool m_ready;
    int m_timerID;
};

#endif // MYMODEL_H
