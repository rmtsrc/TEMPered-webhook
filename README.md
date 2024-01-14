# TEMPered-webhook

TEMPered-webhook is a containerized version of [TEMPered](https://github.com/rmtsrc/TEMPered) which sends the USB device's current temperature and humidity to a webhook.

## Installation

```bash
git clone https://github.com/rmtsrc/TEMPered-webhook.git
cd TEMPered-webhook
git submodule update --init

# Build the container
docker build -t tempered-webhook .
```

### Proxmox notes

#### VM

TEMPer USB device needs to be added to the guest OS in the **Hardware** section.

#### CT/LXC

Pass the device's `/dev/hidraw*` through to the CT by adding the following to `/etc/pve/nodes/pve/lxc/<CT_ID>.conf`

```conf
lxc.cgroup2.devices.allow: c 239:0 rwm
lxc.mount.entry: /dev/hidraw0 dev/hidraw0 none bind,optional,create=file
lxc.cgroup2.devices.allow: c 239:1 rwm
lxc.mount.entry: /dev/hidraw1 dev/hidraw1 none bind,optional,create=file
```

## Usage

Run the container via:

```bash
docker run --rm \
  --device=/dev/hidraw0:/dev/hidraw0 \
  --device=/dev/hidraw1:/dev/hidraw1 \
  --env WEBHOOK_URL=https://example.com/api/webhook/id \
  tempered-webhook
```

### Example Cron Job

Send the USB device's current temperature and humidity to a webhook every 5 minutes:

```crontab
*/5 * * * * docker start tempered-webhook > /dev/null 2>&1 || docker run --name tempered-webhook --device=/dev/hidraw0:/dev/hidraw0 --device=/dev/hidraw1:/dev/hidraw1 --env WEBHOOK_URL=https://example.com/api/webhook/id --label com.centurylinklabs.watchtower.enable=false tempered-webhook > /dev/null 2>&1
```

### Webhook notes

The data is sent as a JSON string in the following format (temperature is in degree Celsius °C):

```json
{
  "temperature": 12.34,
  "humidity": 12.34
}
```

#### Home Assistant

To add a webhook endpoint in Home Assistant the following config can be used:

```yml
template:
  - trigger:
      - platform: webhook
        webhook_id: tempered-webhook-id-ADD-RANDOM-CHARACTERS-HERE
        local_only: true # set to false to allow access from the Internet
    sensor:
      - name: "TEMPer temperature"
        unique_id: "temper_temperature"
        device_class: "temperature"
        state_class: "measurement"
        unit_of_measurement: "°C"
        state: "{{ trigger.json.temperature }}"
      - name: "TEMPer humidity"
        unique_id: "temper_humidity"
        device_class: "humidity"
        state_class: "measurement"
        unit_of_measurement: "%"
        state: "{{ trigger.json.humidity }}"
```

Restart Home Assistant and then update your cron job's `WEBHOOK_URL` to `https://example.com/api/webhook/tempered-webhook-id-ADD-RANDOM-CHARACTERS-HERE`

The sensors can be found in the auto generated dashboard or if you've customised it, the sensors can be added by editing your dashboard, adding a new card by entity and searching for **TEMPer**.
