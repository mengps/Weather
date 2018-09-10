#include "mymodel.h"
#include "weatherdata.h"
#include <QSettings>

class MyModelPrivate
{
public:
    MyModelPrivate() { }
    ~MyModelPrivate() { cleanup(); }

    void cleanup()
    {
        if (!m_index.isEmpty())
        {
            for (auto it : m_index)
                delete it;
            m_index.clear();
        }

        if (!m_data.isEmpty())
        {
            for (auto it : m_data)
                delete it;
            m_data.clear();
        }
    }

public:
    QString m_city;
    QString m_pm25;
    QList<IndexData *> m_index;
    QList<WeatherData *> m_data;
};

MyModel::MyModel(QObject *parent)
    : QObject(parent),
      m_netManager(new QNetworkAccessManager(this)),
      m_ready(false),
      m_dptr(new MyModelPrivate),
      m_api("http://api.map.baidu.com/telematics/v3/weather"
            "?location=武汉&output=json&ak=YGtqUyHOKe5xtaDzi2pmMZVEMdDNlG8F")
{
    readSettings();
    m_geoPosSrc = QGeoPositionInfoSource::createDefaultSource(this);
    connect(m_geoPosSrc, &QGeoPositionInfoSource::positionUpdated, this, &MyModel::updatePosition);
    connect(m_netManager, &QNetworkAccessManager::finished, this, &MyModel::updateWeather);
    m_timerID = startTimer(1000 * 60 * 5);  //五分钟更新一次天气
    m_geoPosSrc->startUpdates();
    //如果位置获取失败,则使用默认位置
    if (m_geoPosSrc->error() != QGeoPositionInfoSource::NoError)
        m_netManager->get(QNetworkRequest(QUrl(m_api)));
}

MyModel::~MyModel()
{
    delete m_dptr;
    if (m_timerID != 0)
        killTimer(m_timerID);
}

void MyModel::readSettings()
{
    QSettings setting("Settings//local.ini", QSettings::IniFormat);
    QString api = setting.value("api").toString();
    if (!api.isEmpty())
        m_api = api;
}

void MyModel::writeSettings()
{
    QSettings setting("Settings//local.ini", QSettings::IniFormat);
    setting.setValue("api", m_api);
}

void MyModel::downRefresh()
{
    setReady(false);
    m_netManager->get(QNetworkRequest(QUrl(m_api)));
}

void MyModel::updatePosition(QGeoPositionInfo gpsPos)
{
    if (gpsPos.isValid())
    {
        //获取经纬度
        QString pos = QString("%1,%2").arg(gpsPos.coordinate().longitude()).arg(gpsPos.coordinate().latitude());
        m_api = QString("http://api.map.baidu.com/telematics/v3/weather"
                        "?location=%1&output=json&ak=YGtqUyHOKe5xtaDzi2pmMZVEMdDNlG8F").arg(pos);
        m_netManager->get(QNetworkRequest(QUrl(m_api)));
        writeSettings();
    }
}

void MyModel::updateWeather(QNetworkReply *reply)
{
    QString str = reply->readAll();
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(str.toUtf8(), &error);
    if (!doc.isNull() && (error.error == QJsonParseError::NoError))
    {
        m_parse.setJsonDocument(doc);
        setPm25(m_parse.getPm25());
        setCity(m_parse.getCurrentCity());
        m_dptr->m_index = m_parse.getIndexList();
        m_dptr->m_data = m_parse.getWeatherList();
        setReady(true);
        emit indexDataChanged();
        emit weatherDataChanged();
    }
}

void MyModel::timerEvent(QTimerEvent *event)
{
    Q_UNUSED(event)
    downRefresh();
}

QQmlListProperty<IndexData> MyModel::indexData()
{
    return QQmlListProperty<IndexData>(this, m_dptr->m_index);
}

QQmlListProperty<WeatherData> MyModel::weatherData()
{
    return QQmlListProperty<WeatherData>(this, m_dptr->m_data);
}

QString MyModel::city() const
{
    return m_dptr->m_city;
}

bool MyModel::ready() const
{
    return m_ready;
}

void MyModel::setReady(bool arg)
{
    if (arg != m_ready)
    {
        m_ready = arg;
        emit readyChanged();
    }
}

QString MyModel::pm25() const
{
    return m_dptr->m_pm25;
}

void MyModel::setCity(const QString &arg)
{
    if (arg != m_dptr->m_city)
    {
        m_dptr->m_city = arg;
        emit cityChanged();
    }
}

void MyModel::setPm25(const QString &arg)
{
    if (arg != m_dptr->m_pm25)
    {
        m_dptr->m_pm25 = arg;
        emit pm25Changed();
    }
}
