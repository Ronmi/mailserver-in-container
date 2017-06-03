<?php

class ChangePasswordMysqlDriver implements \RainLoop\Providers\ChangePassword\ChangePasswordInterface
{
    /**
     * @var string
     */
    private $mHost = '127.0.0.1';

    /**
     * @var string
     */
    private $mUser = '';

    /**
     * @var string
     */
    private $mPass = '';

    /**
     * @var string
     */
    private $mDatabase = '';

    /**
     * @var string
     */
    private $mTable = '';

    /**
     * @var string
     */
    private $mColumn = '';

    /**
     * @var \MailSo\Log\Logger
     */
    private $oLogger = null;

    /**
     * @var array
     */
    private $aDomains = array();

    /**
     * @param string $mHost
     *
     * @return \ChangePasswordMysqlDriver
     */
    public function SetmHost($mHost)
    {
        $this->mHost = $mHost;
        return $this;
    }

    /**
     * @param string $mUser
     *
     * @return \ChangePasswordMysqlDriver
     */
    public function SetmUser($mUser)
    {
        $this->mUser = $mUser;
        return $this;
    }

    /**
     * @param string $mPass
     *
     * @return \ChangePasswordMysqlDriver
     */
    public function SetmPass($mPass)
    {
        $this->mPass = $mPass;
        return $this;
    }

    /**
     * @param string $mDatabase
     *
     * @return \ChangePasswordMysqlDriver
     */
    public function SetmDatabase($mDatabase)
    {
        $this->mDatabase = $mDatabase;
        return $this;
    }

    /**
     * @param string $mTable
     *
     * @return \ChangePasswordMysqlDriver
     */
    public function SetmTable($mTable)
    {
        $this->mTable = $mTable;
        return $this;
    }

    /**
     * @param string $mColumn
     *
     * @return \ChangePasswordMysqlDriver
     */
    public function SetmColumn($mColumn)
    {
        $this->mColumn = $mColumn;
        return $this;
    }

    /**
     * @param \MailSo\Log\Logger $oLogger
     *
     * @return \ChangePasswordMysqlDriver
     */
    public function SetLogger($oLogger)
    {
        if ($oLogger instanceof \MailSo\Log\Logger)
        {
            $this->oLogger = $oLogger;
        }

        return $this;
    }

    /**
     * @param array $aDomains
     *
     * @return bool
     */
    public function SetAllowedDomains($aDomains)
    {
        if (\is_array($aDomains) && 0 < \count($aDomains))
        {
            $this->aDomains = $aDomains;
        }

        return $this;
    }

    /**
     * @param \RainLoop\Account $oAccount
     *
     * @return bool
     */
    public function PasswordChangePossibility($oAccount)
    {
        return $oAccount && $oAccount->Domain() &&
            \in_array(\strtolower($oAccount->Domain()->Name()), $this->aDomains);
    }

    private function CRAMMD5($pass)
    {
        $ret = trim(shell_exec('doveadm pw -p ' . escapeshellarg($pass)));
        return $ret;
    }

    private function log($msg)
    {
        if ($this->oLogger)
        {
            $this->oLogger->Write('No such user in DB!?');
            return;
        }
    }

    /**
     * @param \RainLoop\Account $oAccount
     * @param string $sPrevPassword
     * @param string $sNewPassword
     *
     * @return bool
     */
    public function ChangePassword(\RainLoop\Account $oAccount, $sPrevPassword, $sNewPassword)
    {
        if ($this->oLogger)
        {
            $this->oLogger->Write('Try to change password for '.$oAccount->Email());
        }

        $bResult = false;

        $dsn = 'mysql:host='.$this->mHost.';dbname='.$this->mDatabase.';charset=utf8';
        $options = array(
            PDO::ATTR_EMULATE_PREPARES  => false,
            PDO::ATTR_PERSISTENT        => true,
            PDO::ATTR_ERRMODE           => PDO::ERRMODE_EXCEPTION
        );

        try
        {
            $conn = new PDO($dsn,$this->mUser,$this->mPass,$options);
            $select = $conn->prepare("SELECT $this->mColumn FROM $this->mTable WHERE username = :id LIMIT 1");
            $select->execute(array(
                ':id'     => $oAccount->Email()
            ));

            $colCrypt = $select->fetchAll(PDO::FETCH_ASSOC);
            $sCryptPass = $colCrypt[0][$this->mColumn];

            if (strlen($sCryptPass) < 1) {
                $this->log('No such user in DB!?');
                return false;
            }

            $oldHash = $this->CRAMMD5($sPrevPassword);
            if ($oldHash != $sCryptPass) {
                $this->log('User provides wrong old password.');
                return false;
            }

            if (mb_strlen($sNewPassword) < 8) {
                $this->log('New password needs to be at least 8 characters.');
                return false;
            }

            $newHash = $this->CRAMMD5($sNewPassword);

            $update = $conn->prepare("UPDATE $this->mTable SET $this->mColumn = :crypt WHERE username = :id");
            $update->execute(array(
                ':id'    => $oAccount->Email(),
                ':crypt' => $newHash,
            ));

            $bResult = true;
            $this->log('Success! Password changed.');
        }
        catch (\Exception $oException)
        {
            $bResult = false;
            $this->log($oException);
        }

        return $bResult;
    }
}
