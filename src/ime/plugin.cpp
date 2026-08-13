#include "eastasianime.h"

#include <QQmlExtensionPlugin>
#include <qqml.h>

class EastAsianImePlugin final : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override
    {
        qmlRegisterType<EastAsianIme>(uri, 1, 0, "EastAsianIme");
    }
};

#include "plugin.moc"
